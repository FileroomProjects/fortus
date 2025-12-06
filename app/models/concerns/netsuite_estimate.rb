module NetsuiteEstimate
  extend ActiveSupport::Concern

  included do
    def create_ns_estimate(payload)
      ns_estimate = Netsuite::Estimate.create(payload)
      process_response("Netsuite Estimate", "create", ns_estimate)
    end

    def find_ns_estimate(netsuite_estimate_id)
      estimate = Netsuite::Estimate.show(netsuite_estimate_id)
      process_response("Netsuite Estimate", "found", estimate)
    end
  end
end
