module HubspotDeal
  extend ActiveSupport::Concern

  included do
    def find_hs_deal(filters, raise_error: true)
      payload = build_search_payload(filters)
      deal = Hubspot::Deal.search(payload)
      if object_present_with_id?(deal)
        Rails.logger.info "[INFO] [API.HUBSPOT.DEAL] [SEARCH] [deal_id: #{deal[:id]}] HubSpot deal found"
        deal
      else
        Rails.logger.info "[INFO] [API.HUBSPOT.DEAL] [SEARCH] [filters: #{filters}] HubSpot deal not found"
        raise "Hubspot DEAL not found" if raise_error
        nil
      end
    end

    def update_hs_deal(payload)
      updated_deal = Hubspot::Deal.update(payload)
      process_response("Hubspot Deal", "updated", updated_deal)
    end

    def create_hs_deal(payload)
      deal = Hubspot::Deal.create(payload)
      process_response("Hubspot Deal", "created", deal)
    end
  end
end
