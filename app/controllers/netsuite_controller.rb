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
      token_data = Netsuite::Base.exchange_code_for_token(code)
      render_success("NetSuite authentication successful!", token_data)
    rescue => e
      Rails.logger.error "NetSuite OAuth2 error: #{e.message}"
      render_failure("NetSuite authentication failed: #{e.message}", e.message)
    end
  end

  def sync_order
    # validate_sync_order_params(%w[sales_order customer opportunity items])

    netsuite = Netsuite::SalesOrder.new(params["netsuite"])
    netsuite.sync_sales_order_with_hubspot
    render json: { success: true }
  end

  def sync_estimate
    # validate_sync_order_params(%w[estimateId customer opportunity lineitems])

    netsuite = Netsuite::Quote.new(params["netsuite"])
    netsuite.sync_quote_estimate_with_quote_deal
    render json: { success: true }
  end

  def sync_deal
    # validate_sync_order_params(%w[opportunity])

    netsuite = Netsuite::Opportunity.new(params["netsuite"])
    netsuite.sync_opportunity_with_deal
    render json: { success: true }
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
          flash[:alert] = "NetSuite authentication failed: #{e.message}"
          redirect_to root_path
        end
        format.json { render json: { error: "Authentication failed", message: e.message }, status: :internal_server_error }
      end
    end
end
