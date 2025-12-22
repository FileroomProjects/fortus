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

    # Finds the NetSuite location ID for a given customer.
    # Step 1: Fetches the subsidiary ID using the provided customer ID.
    # Step 2: Retrieve all active locations from NetSuite.
    # Step 3: Selects the location where the subsidiary ID matches
    #         and returns the corresponding location ID.
    def find_ns_location_id(customer_id)
      subsidiary_id = find_subsidiary_id(customer_id)

      return nil unless subsidiary_id.present?

      Rails.logger.info "[INFO] [API.NETSUITE.CUSTOMER] [FETCH] [customer_id: #{customer_id}, subsidiary id: #{subsidiary_id}] Fetched netsuite customer"

      location = Netsuite::Location.find_by_subsidiary_id(subsidiary_id)
      process_response("Netsuite Location", "found", location)
      location[:id]
    end

    # Fetches customer details using customer ID
    # and returns the associated subsidiary ID.
    def find_subsidiary_id(customer_id)
      customer = fetch_ns_customer(customer_id)

      unless customer
        Rails.logger.warn "[WARN] [API.NETSUITE.CUSTOMER] [FETCH] [customer_id: #{customer_id}] Customer not found."
        return nil
      end

      customer.dig(:subsidiary, :id)
    end
  end
end
