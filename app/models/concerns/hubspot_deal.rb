module HubspotDeal
  extend ActiveSupport::Concern

  included do
    # Search for a HubSpot deal using the given filters.
    # - raise_error: whether to raise if no deal is found
    def find_hs_deal(filters, raise_error: true)
      payload = build_search_payload(filters)
      deal = Hubspot::Deal.search(payload)

      if object_present_with_id?(deal)
        Rails.logger.info "[INFO] [API.HUBSPOT.DEAL] [SEARCH] [deal_id: #{deal[:id]}] HubSpot deal found"
        deal
      end

      Rails.logger.info "[INFO] [API.HUBSPOT.DEAL] [SEARCH] [filters: #{filters}] HubSpot deal not found"
      raise "Hubspot DEAL not found" if raise_error
      nil
    end

    # Update a HubSpot deal with the provided payload.
    def update_hs_deal(payload)
      updated_deal = Hubspot::Deal.update(payload)
      process_response("Hubspot Deal", "updated", updated_deal)
    end

    # Create a new HubSpot deal using the provided payload.
    def create_hs_deal(payload)
      deal = Hubspot::Deal.create(payload)
      process_response("Hubspot Deal", "created", deal)
    end

    def hs_child_deal_sync_success_log(deal, action, ns_estimate_id)
      Rails.logger.info "[INFO] [SYNC.NETSUITE_TO_HUBSPOT.ESTIMATE] [#{action}] [estimate_id: #{ns_estimate_id}, deal_id: #{deal[:id]}] Deal #{action.downcase}d successfully"
      Rails.logger.info "[INFO] [SYNC.NETSUITE_TO_HUBSPOT.ESTIMATE] [COMPLETE] [estimate_id: #{ns_estimate_id}, deal_id: #{deal[:id]}] Estimate synchronized successfully"
      deal
    end

    def hs_deal_sync_success_log(deal, action, ns_opportunity_id)
      Rails.logger.info "[INFO] [SYNC.NETSUITE_TO_HUBSPOT.OPPORTUNITY] [#{action}] [opportunity_id: #{ns_opportunity_id}, deal_id: #{deal[:id]}] Deal #{action.downcase}d successfully"
      Rails.logger.info "[INFO] [SYNC.NETSUITE_TO_HUBSPOT.OPPORTUNITY] [COMPLETE] [opportunity_id: #{ns_opportunity_id}, deal_id: #{deal[:id]}] Opportunity synchronized successfully"
      deal
    end
  end
end
