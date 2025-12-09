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
  end
end
