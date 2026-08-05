class HubspotsController < ApplicationController
  include NsEstimateCreation
  protect_from_forgery with: :null_session
  before_action :load_deal, only: [ :create_duplicate_ns_quote, :create_ns_quote, :link_netsuite_opportunity ]

  def create_contact_customer
    Rails.logger.info "[INFO] [CONTROLLER.HUBSPOT] [START] [{ deal_id: #{deal_id} }] Starting deal-opportunity sync workflow"

    begin
      @hubspot = Hubspot::Deal.new(params["hubspot"])
      @hubspot.sync_contact_customer_with_netsuite

      Rails.logger.info "[INFO] [CONTROLLER.HUBSPOT] [COMPLETE] [{ deal_id: #{deal_id} }] Completed deal-opportunity sync workflow"
      render json: { success: true }
    rescue ActionController::InvalidAuthenticityToken => e
      Rails.logger.error "[ERROR] [AUTH.NETSUITE] [FAIL] [provider:netsuite] #{e.message}"
      render json: { error: e.message }, status: :unauthorized
    rescue => e
      Rails.logger.error "[ERROR] [CONTROLLER.HUBSPOT] [FAIL] [{ deal_id: #{deal_id} }] Deal-opportunity sync workflow failed: #{e.class}: #{e.message}"
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  def create_ns_quote
    Rails.logger.info "[INFO] [CONTROLLER.HUBSPOT] [START] [{ deal_id: #{deal_id} }] Starting NetSuite estimate creation"
    perform_ns_estimate_creation(@hubspot, :prepare_payload_for_netsuite_estimate, "NetSuite estimate")
  end

  def link_netsuite_opportunity
    Rails.logger.info "[INFO] [CONTROLLER.HUBSPOT] [START] [{ deal_id: #{deal_id} }] Starting NetSuite opportunity linking"

    begin
      opportunity = Netsuite::Opportunity.show(params["opportunityId"])
      @hubspot.update_from_opportunity(opportunity)

      Rails.logger.info "[INFO] [CONTROLLER.HUBSPOT] [COMPLETE] [{ deal_id: #{deal_id} }] Completed NetSuite opportunity linking"
      render json: { success: true }
    rescue ActionController::InvalidAuthenticityToken => e
      Rails.logger.error "[ERROR] [AUTH.NETSUITE] [FAIL] [provider:netsuite] #{e.message}"
      render json: { error: e.message }, status: :unauthorized
    rescue => e
      Rails.logger.error "[ERROR] [CONTROLLER.HUBSPOT] [FAIL] [{ deal_id: #{deal_id} }] NetSuite opportunity linking failed: #{e.class}: #{e.message}"
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  def create_ns_note
    opportunity_id = params["properties"]["netsuite_opportunity_id"]["value"] rescue nil
    note = params["properties"]["request_quote_notes"]["value"] rescue nil
    deal_id = params["properties"]["hs_object_id"]["value"] rescue nil
    deal_company = HTTParty.get("https://api.hubapi.com/crm/v4/objects/deals/#{deal_id}/associations/companies",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['HUBSPOT_ACCESS_TOKEN']}" })
    associated_company = deal_company["results"].first["toObjectId"] rescue nil


    netsuite_customer = HTTParty.get("https://api.hubspot.com/crm/v3/objects/companies/#{associated_company}?properties=netsuite_company_id",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['HUBSPOT_ACCESS_TOKEN']}" }) rescue nil

    netsuite_customer_id = netsuite_customer["properties"]["netsuite_company_id"] rescue nil
    owner_id = params["properties"]["hubspot_owner_id"]["value"] rescue nil
    if owner_id.present?
      owner_response = HTTParty.get(
        "https://api.hubapi.com/crm/v3/owners/#{owner_id}",
        headers: {
          "Authorization" => "Bearer #{ENV['HUBSPOT_ACCESS_TOKEN']}",
          "Content-Type" => "application/json"
        }
      )
      owner = JSON.parse(owner_response.body)
      owner_email = owner["email"] rescue nil

      employee_response = HTTParty.get(
        "https://#{ENV['NETSUITE_ACCOUNT_ID']}.suitetalk.api.netsuite.com/services/rest/record/v1/employee",
        query: {
          q: "email IS \"#{owner_email}\""
        },
        headers: {
          "Authorization" => "Bearer #{Netsuite::Base.get_access_token}",
          "Content-Type" => "application/json"
        }
      )

      employee = JSON.parse(employee_response.body)["items"]&.first rescue nil
      employee_id = employee["id"] if employee
    end
    perth_time = Time.find_zone!("Australia/Perth").now

    if opportunity_id.present? && netsuite_customer_id.present? && note.present? && employee_id.present?

      body = {
        title: note,
        message: note,
        priority: "HIGH",
        timedEvent: true,
        startDate: perth_time.strftime("%Y-%m-%d"),
        startTime: perth_time.strftime("%H:%M"),
        dueDate: perth_time.strftime("%Y-%m-%d"),
        timezone: "Australia/Perth",
        assigned: {id: 169271},
        company: {id: netsuite_customer_id},
        transaction: {id: opportunity_id},
        owner: {id: employee_id}
      }
      ass_response = HTTParty.post(
      "https://#{ENV['NETSUITE_ACCOUNT_ID']}.suitetalk.api.netsuite.com/services/rest/record/v1/task",
      body: body.to_json,
      headers: {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{Netsuite::Base.get_access_token}"
      }
    )
    elsif opportunity_id.present? && netsuite_customer_id.present? && note.present? && employee_id.blank?
      body = {
        title: note,
        message: note,
        priority: "HIGH",
        timedEvent: true,
        startDate: perth_time.strftime("%Y-%m-%d"),
        startTime: perth_time.strftime("%H:%M"),
        dueDate: perth_time.strftime("%Y-%m-%d"),
        assigned: {id: 169271},
        timezone: "Australia/Perth",
        company: {id: netsuite_customer_id},
        transaction: {id: opportunity_id}
      }
      ass_response = HTTParty.post(
      "https://#{ENV['NETSUITE_ACCOUNT_ID']}.suitetalk.api.netsuite.com/services/rest/record/v1/task",
      body: body.to_json,
      headers: {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{Netsuite::Base.get_access_token}"
      }
      )
    else
      render json: { error: "No opportunity or note found" }, status: :not_found
    end
  end


  def create_duplicate_ns_quote
    Rails.logger.info "[INFO] [CONTROLLER.HUBSPOT] [START] [{ deal_id: #{deal_id} }] Starting duplicate NetSuite estimate creation"
    perform_ns_estimate_creation(@hubspot, :prepare_payload_for_duplicate_netsuite_estimate, "Duplicate NetSuite estimate")
  end

  private
    def load_deal
      @hs_deal = Hubspot::Deal.find_by(deal_id: deal_id)

      unless @hs_deal.present?
        render json: { error: "Deal not found" }, status: :not_found and return
      end

      @hubspot = Hubspot::Deal.new(@hs_deal)
    end

    def deal_id
      params[:objectId] || params[:deal_id] || params[:dealId]
    end
end
