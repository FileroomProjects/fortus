module NsEstimateCreation
  extend ActiveSupport::Concern

  # Performs payload preparation, NetSuite estimate creation, logging and response handling.
  # - hubspot: instance that responds to the payload method and `create_ns_estimate`
  # - payload_method: symbol of the method to call on hubspot to prepare payload
  # - label: human-friendly label used in logs and error messages
  def perform_ns_estimate_creation(hubspot, payload_method, label)
    Rails.logger.info "[INFO] [SYNC.HUBSPOT_TO_NETSUITE.DEAL] [START] [deal_id: #{deal_id}] Initiating child deal synchronization"

    begin
      payload = hubspot.public_send(payload_method)
      @ns_estimate = hubspot.create_ns_estimate(payload)

      if @ns_estimate[:id].present?
        Rails.logger.info "[INFO] [SYNC.HUBSPOT_TO_NETSUITE.DEAL] [CREATE] [deal_id: #{deal_id}, estimate_id: #{@ns_estimate[:id]}] Estimate created succesfully"
        Rails.logger.info "[INFO] [SYNC.HUBSPOT_TO_NETSUITE.DEAL] [COMPLETE] [deal_id: #{deal_id}, estimate_id: #{@ns_estimate[:id]}] Child deal synchronized successfully"
      end

      Rails.logger.info "[INFO] [CONTROLLER.HUBSPOT] [COMPLETE] [{ deal_id: #{deal_id} }] Completed #{label} creation"
      respond_to { |format| format.html }
    rescue ActionController::InvalidAuthenticityToken => e
      Rails.logger.error "[ERROR] [AUTH.NETSUITE] [FAIL] [provider:netsuite] #{e.message}"
      respond_to do |format|
        format.html do
          flash[:alert] = e.message
          redirect_to root_path
        end
        format.json { render json: { error: "Authentication failed", message: e.message }, status: :unauthorized }
      end
    rescue => e
      Rails.logger.error "[ERROR] [CONTROLLER.HUBSPOT] [FAIL] [{ deal_id: #{deal_id} }] #{label.capitalize} creation failed: #{e.class}: #{e.message}"
      respond_to do |format|
        format.html do
          flash[:alert] = "#{label.capitalize} creation failed: #{e.class}: #{e.message}"
        end
        format.json { render json: { error: "#{label.capitalize} creation failed", message: e.message }, status: :internal_server_error }
      end
    end
  end
end
