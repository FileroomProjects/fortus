class HubspotsController < ApplicationController
  protect_from_forgery with: :null_session
  before_action :load_deal, only: [ :create_duplicate_ns_quote, :create_ns_quote ]

  def create_contact_customer
    Rails.logger.info "[INFO] [CONTROLLER.HUBSPOT] [START] [{ deal_id: #{deal_id} }] Starting deal-opportunity sync workflow"

    begin
      @hubspot = Hubspot::Deal.new(params["hubspot"])
      @hubspot.sync_contact_customer_with_netsuite

      Rails.logger.info "[INFO] [CONTROLLER.HUBSPOT] [COMPLETE] [{ deal_id: #{deal_id} }] Completed deal-opportunity sync workflow"
      render json: { success: true }
    rescue => e
      Rails.logger.error "[ERROR] [CONTROLLER.HUBSPOT] [FAIL] [{ deal_id: #{deal_id} }] Deal-opportunity sync workflow failed: #{e.class}: #{e.message}"
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  def create_ns_quote
    Rails.logger.info "[INFO] [CONTROLLER.HUBSPOT] [START] [{ deal_id: #{deal_id} }] Starting NetSuite estimate creation"
    Rails.logger.info "[INFO] [SYNC.HUBSPOT_TO_NETSUITE.DEAL] [START] [deal_id: #{deal_id}] Initiating child deal synchronization"

    begin
      payload = @hubspot.prepare_payload_for_netsuite_estimate
      @ns_estimate = @hubspot.create_ns_estimate(payload)

      if @ns_estimate[:id].present?
        Rails.logger.info "[INFO] [SYNC.HUBSPOT_TO_NETSUITE.DEAL] [CREATE] [deal_id: #{deal_id}, estimate_id: #{@ns_estimate[:id]}] Estimate created succesfully"
        Rails.logger.info "[INFO] [SYNC.HUBSPOT_TO_NETSUITE.DEAL] [COMPLETE] [deal_id: #{deal_id}, estimate_id: #{@ns_estimate[:id]}] Child deal synchronized successfully"
      end
      Rails.logger.info "[INFO] [CONTROLLER.HUBSPOT] [COMPLETE] [{ deal_id: #{deal_id} }] Completed NetSuite estimate creation"
      respond_to { |format| format.html }
    rescue => e
      Rails.logger.error "[ERROR] [CONTROLLER.HUBSPOT] [FAIL] [{ deal_id: #{deal_id} }] NetSuite estimate creation failed: #{e.class}: #{e.message}"
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  def create_duplicate_ns_quote
    Rails.logger.info "[INFO] [CONTROLLER.HUBSPOT] [START] [{ deal_id: #{deal_id} }] Starting duplicate NetSuite estimate creation"
    Rails.logger.info "[INFO] [SYNC.HUBSPOT_TO_NETSUITE.DEAL] [START] [deal_id: #{deal_id}] Initiating child deal synchronization"

    begin
      payload = @hubspot.prepare_payload_for_duplicate_netsuite_estimate
      @ns_estimate = @hubspot.create_ns_estimate(payload)

      if @ns_estimate[:id].present?
        Rails.logger.info "[INFO] [SYNC.HUBSPOT_TO_NETSUITE.DEAL] [CREATE] [deal_id: #{deal_id}, estimate_id: #{@ns_estimate[:id]}] Estimate created succesfully"
        Rails.logger.info "[INFO] [SYNC.HUBSPOT_TO_NETSUITE.DEAL] [COMPLETE] [deal_id: #{deal_id}, estimate_id: #{@ns_estimate[:id]}] Child deal synchronized successfully"
      end
      Rails.logger.info "[INFO] [CONTROLLER.HUBSPOT] [COMPLETE] [{ deal_id: #{deal_id} }] Completed duplicate NetSuite estimate creation"
      respond_to { |format| format.html }
    rescue => e
      Rails.logger.error "[ERROR] [CONTROLLER.HUBSPOT] [FAIL] [{ deal_id: #{deal_id} }] Duplicate NetSuite estimate creation failed: #{e.class}: #{e.message}"
      render json: { error: e.message }, status: :internal_server_error
    end
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
