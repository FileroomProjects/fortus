class HubspotsController < ApplicationController
  include NsEstimateCreation
  protect_from_forgery with: :null_session
  before_action :load_deal, only: [ :create_duplicate_ns_quote, :create_ns_quote ]

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

  def create_ns_note
    opportunity_id = params["properties"]["netsuite_opportunity_id"]["value"] rescue nil
    note = params["properties"]["request_quote_notes"]["value"] rescue nil
    deal_id = params["properties"]["hs_object_id"]["value"] rescue nil
    deal_company = HTTParty.get("https://api.hubapi.com/crm/v4/objects/deals/#{deal_id}/associations/companies",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['HUBSPOT_ACCESS_TOKEN']}" })
    associated_company = deal_company["results"].first["toObjectId"] rescue nil


    netsuite_customer = HTTParty.get("https://api.hubspot.com/crm/v3/objects/companies/#{associated_company}?properties=netsuite_company_id",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['HUBSPOT_ACCESS_TOKEN']}" }) rescue nil

    netsuite_customer_id = netsuite_customer["properties"]["netsuite_company_id"] rescue nil
    if opportunity_id.present? && netsuite_customer_id.present? && note.present?
      body = {
        title: note,
        message: note,
        priority: "HIGH",
        dueDate: (Date.today+1.day).strftime("%Y-%m-%d"),
        timedEvent: true,
        company: { id: netsuite_customer_id },
        transaction: { id: opportunity_id }
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
