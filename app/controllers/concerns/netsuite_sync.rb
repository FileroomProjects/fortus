module NetsuiteSync
  extend ActiveSupport::Concern

  # Perform a Netsuite sync action with common logging, validation and error handling.
  # options:
  #  - netsuite_class: Class (e.g. Netsuite::SalesOrder)
  #  - sync_method: Symbol method to call on instance (e.g. :sync_sales_order_with_hubspot)
  #  - required: Array of required keys under params[:netsuite] (strings)
  #  - label: String label used in logs
  #  - context: Hash of additional context values for logging
  def perform_netsuite_sync(netsuite_class:, sync_method:, required: [], label: nil, context: {})
    validate_sync_order_params(required)

    Rails.logger.info "[INFO] [CONTROLLER.NETSUITE] [START] [#{context}] Starting #{label} sync workflow"

    begin
      netsuite = netsuite_class.new(params["netsuite"])
      netsuite.public_send(sync_method)

      Rails.logger.info "[INFO] [CONTROLLER.NETSUITE] [COMPLETE] [#{context}] Completed #{label} sync workflow"
      render json: { success: true }
    rescue ActionController::InvalidAuthenticityToken => e
      Rails.logger.error "[ERROR] [AUTH.NETSUITE] [FAIL] [provider:netsuite] #{e.message}"
      render json: { error: e.message }, status: :unauthorized
    rescue => e
      Rails.logger.error "[ERROR] [CONTROLLER.NETSUITE] [FAIL] [#{context}] #{label.capitalize} sync workflow failed: #{e.class}: #{e.message}"
      render json: { error: e.message }, status: :internal_server_error
    end
  end
end
