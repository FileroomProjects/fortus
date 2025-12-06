module HubspotDeal
  extend ActiveSupport::Concern

  included do
    def find_hs_deal(filters, raise_error: true)
      payload = build_search_payload(filters)
      deal = Hubspot::Deal.search(payload)
      process_response("Hubspot Deal", "found", deal, raise_error)
    end

    def update_hs_deal(payload)
      updated_deal = Hubspot::Deal.update(payload)
      process_response("Hubspot Deal", "update", updated_deal)
    end

    def create_hs_deal(payload)
      deal = Hubspot::Deal.create(payload)
      process_response("Hubspot Deal", "create", deal)
    end
  end
end
