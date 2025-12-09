class NetsuiteController < ApplicationController
  protect_from_forgery with: :null_session

  # GET /netsuite/callback
  def callback
    code = params[:code]
    error = params[:error]

    if error
      return render json: { error: "OAuth2 error: #{error}", description: params[:error_description] }, status: :bad_request
    end

    unless code
      return render json: { error: "Authorization code not provided" }, status: :bad_request
    end

    begin
      Rails.logger.info "[INFO] [AUTH.NETSUITE] [FETCH] [provider:netsuite] Retrieving access token"
      token_data = Netsuite::Base.exchange_code_for_token(code)
      render_success("NetSuite authentication successful!", token_data)
    rescue => e
      Rails.logger.error "[ERROR] [AUTH.NETSUITE] [FAIL] [provider:netsuite] Retrieving access token failed: #{e.message}"
      render_failure("NetSuite authentication failed: #{e.message}", e.message)
    end
  end

  def sync_order
    # validate_sync_order_params(%w[sales_order customer opportunity items])
    Rails.logger.info "[INFO] [CONTROLLER.NETSUITE] [START] [{ sales_order_id: #{sales_order_id} }] Starting sales_order-order sync workflow"

    begin
      netsuite = Netsuite::SalesOrder.new(params["netsuite"])
      netsuite.sync_sales_order_with_hubspot

      Rails.logger.info "[INFO] [CONTROLLER.NETSUITE] [COMPLETE] [{ sales_order_id: #{sales_order_id} }] Completed sales_order-order sync workflow"
      render json: { success: true }
    rescue => e
      Rails.logger.error "[ERROR] [CONTROLLER.NETSUITE] [FAIL] [{ sales_order_id: #{sales_order_id} }] Sales_order-order sync workflow failed: #{e.class}: #{e.message}"
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  def sync_estimate
    # validate_sync_order_params(%w[estimateId customer contact items])
    Rails.logger.info "[INFO] [CONTROLLER.NETSUITE] [START] [{ estimate_id: #{estimate_id} }] Starting estimate-child_deal sync workflow"

    begin
      netsuite = Netsuite::Estimate.new(params["netsuite"])
      netsuite.sync_ns_estimate_with_hs_child_deal

      Rails.logger.info "[INFO] [CONTROLLER.NETSUITE] [COMPLETE] [{ estimate_id: #{estimate_id} }] Completed estimate-child_deal sync workflow"
      render json: { success: true }
    rescue => e
      Rails.logger.error "[ERROR] [CONTROLLER.NETSUITE] [FAIL] [{ estimate_id: #{estimate_id} }] Estimate-child_deal sync workflow failed: #{e.class}: #{e.message}"
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  def sync_deal
    # validate_sync_order_params(%w[opportunity])
    Rails.logger.info "[INFO] [CONTROLLER.NETSUITE] [START] [{ opportunity_id: #{opportunity_id} }] Starting opportunity-deal sync workflow"

    begin
      netsuite = Netsuite::Opportunity.new(params["netsuite"])
      netsuite.sync_opportunity_with_deal

      Rails.logger.info "[INFO] [CONTROLLER.NETSUITE] [COMPLETE] [{ opportunity_id: #{opportunity_id} }] Completed opportunity-deal sync workflow"
      render json: { success: true }
    rescue => e
      Rails.logger.error "[ERROR] [CONTROLLER.NETSUITE] [FAIL] [{ opportunity_id: #{opportunity_id} }] Opportunity-deal sync workflow failed: #{e.class}: #{e.message}"
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  private
    def validate_sync_order_params(required)
      netsuite = params.require(:netsuite).to_unsafe_h

      missing = required.reject { |key| netsuite[key].present? }

      raise "Missing required fields #{missing}" if missing.any?
    end

    def render_success(message, token_data)
      respond_to do |format|
        format.html do
          flash[:notice] = message
          redirect_to root_path
        end
        format.json { render json: { message: "Authentication successful", token_data: token_data } }
      end
    end

    def render_failure(alert_message, error_message)
      respond_to do |format|
        format.html do
          flash[:alert] = "NetSuite authentication failed: #{error_message}"
          redirect_to root_path
        end
        format.json { render json: { error: "Authentication failed", message: error_message }, status: :internal_server_error }
      end
    end

    def sales_order_id
      params["netsuite"]["sales_order"]["id"]
    end

    def estimate_id
      params["netsuite"]["estimateId"]
    end

    def opportunity_id
      params["netsuite"]["opportunity_id"]
    end
end
