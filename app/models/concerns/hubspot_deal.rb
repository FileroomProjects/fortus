module HubspotDeal
  extend ActiveSupport::Concern

  included do
    # Search for a HubSpot deal using the given filters.
    # - raise_error: whether to raise if no deal is found
    def find_hs_deal(filters, raise_error: true)
      payload = build_search_payload(filters).merge(include_version_properties)
      deal = Hubspot::Deal.search(payload)

      if object_present_with_id?(deal)
        Rails.logger.info "[INFO] [API.HUBSPOT.DEAL] [SEARCH] [deal_id: #{deal[:id]}] HubSpot deal found"
        return deal
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

    def find_child_deal_version(parent_deal)
      Rails.logger.info "[INFO] [API.HUBSPOT.ASSOCIATED] [FETCH] [deal_id: #{parent_deal[:id]}] Fetching child deals to determine the next deal version"
      child_deals = Hubspot::Deal.child_deals(parent_deal[:id])
      if child_deals.present?
        child_deal_ids = child_deals.map { |deal| deal["toObjectId"] }
        Rails.logger.info "[INFO] [API.HUBSPOT.ASSOCIATED] [FETCH] [deal_id: #{parent_deal[:id]}, child_deals: #{child_deal_ids}, new_deal_version: #{child_deals.count + 1}] child deals found"
        child_deals.count + 1
      else
        Rails.logger.info "[INFO] [API.HUBSPOT.ASSOCIATED] [FETCH] [deal_id: #{parent_deal[:id]}, new_deal_version: 1] No child deals found"
        1
      end
    end

    private
      def include_version_properties
        {
          "properties": [ "version" ]
        }
      end
  end
end
