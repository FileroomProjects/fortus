module NetsuiteEstimate
  extend ActiveSupport::Concern

  included do
    # Create a Netsuite estimate via the payload.
    def create_ns_estimate(payload)
      ns_estimate = Netsuite::Estimate.create(payload)
      process_response("Netsuite Estimate", "create", ns_estimate)
    end

    # Retrieve a Netsuite estimate by ID and validate the response.
    def find_ns_estimate(netsuite_estimate_id)
      estimate = Netsuite::Estimate.show(netsuite_estimate_id)
      process_response("Netsuite Estimate", "found", estimate)
    end

    def find_ns_location_id_by_customer_id(customer_id)
      customer = fetch_ns_customer(customer_id)
      subsidiary_id = customer.dig(:subsidiary, :id)
      Rails.logger.info "[INFO] [API.NETSUITE.CUSTOMER] [FETCH] [customer_id: #{customer_id}] Fetched netsuite customer subsidiary id: #{subsidiary_id}"
      location = Netsuite::Location.find_by_subsidiary(subsidiary_id)
      process_response("Netsuite Location", "found", location)
      location[:id]
    end
  end
end
