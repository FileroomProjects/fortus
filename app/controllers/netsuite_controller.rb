class NetsuiteController < ApplicationController
  include NetsuiteSync
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
    perform_netsuite_sync(
      netsuite_class: Netsuite::SalesOrder,
      sync_method: :sync_sales_order_with_hubspot,
      required: %w[sales_order customer opportunity items],
      label: "salesOrder-order",
      context: { sales_order_id: params["netsuite"]["sales_order"]["id"] }
    )
  end

  def sync_estimate
    perform_netsuite_sync(
      netsuite_class: Netsuite::Estimate,
      sync_method: :sync_ns_estimate_with_hs_child_deal,
      required: %w[estimateId customer contact items],
      label: "estimate-deal",
      context: { estimate_id: params["netsuite"]["estimateId"] }
    )
  end

  def sync_opportunity
    perform_netsuite_sync(
      netsuite_class: Netsuite::Opportunity,
      sync_method: :sync_opportunity_with_deal,
      required: %w[opportunity],
      label: "opportunity-deal",
      context: { opportunity_id: params["netsuite"]["opportunity_id"] }
    )
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
end
