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
    opportunity_id = params["properties"]["netsuite_opportunity_id"]["value"]
    note = params["properties"]["request_quote_notes"]["value"]
    if opportunity_id.present? || note.present?
      restlet = Netsuite::RestletNote.new
      response = restlet.create_note(
        opportunity_id: opportunity_id,
        note: note,
        title: note  # optional
      )

      if  response["success"] ==  true
        Rails.logger.info "[INFO] [CONTROLLER.HUBSPOT] [COMPLETE] [{ opportunity_id: #{opportunity_id} }] NetSuite note created successfully"
        render json: { success: true, response: response }
      else
        Rails.logger.error "[ERROR] [CONTROLLER.HUBSPOT] [FAIL] [{ opportunity_id: #{opportunity_id} }] NetSuite note creation failed: #{response[:error]}"
        render json: { error: response[:error] }, status: :internal_server_error
      end
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
