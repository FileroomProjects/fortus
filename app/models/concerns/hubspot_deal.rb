module HubspotDeal
  extend ActiveSupport::Concern

  included do
    # Search for a HubSpot deal using the given filters.
    # - raise_error: whether to raise if no deal is found
    def find_hs_deal(filters, raise_error: true)
      payload = build_search_payload(filters)
      deal = Hubspot::Deal.search(payload)
      process_response("Hubspot Deal", "found", deal, raise_error)
    end

    # Update a HubSpot deal with the provided payload.
    def update_hs_deal(payload)
      updated_deal = Hubspot::Deal.update(payload)
      process_response("Hubspot Deal", "update", updated_deal)
    end

    # Create a new HubSpot deal using the provided payload.
    def create_hs_deal(payload)
      deal = Hubspot::Deal.create(payload)
      process_response("Hubspot Deal", "create", deal)
    end
  end
end
