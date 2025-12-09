module Netsuite::Opportunity::Hubspot::DealHelper
  extend ActiveSupport::Concern

  included do
    def update_hubspot_deal
      Rails.logger.info "[INFO] [SYNC.NETSUITE_TO_HUBSPOT.OPPORTUNITY] [START] [opportunity_id: #{args[:opportunity][:id]}] Initiating opportunity synchronization"
      hs_deal = find_hs_deal(deal_filters)
      payload = payload_to_update_deal(hs_deal[:id])
      hs_deal = update_hs_deal(payload)
      Rails.logger.info "[INFO] [SYNC.NETSUITE_TO_HUBSPOT.OPPORTUNITY] [UPDATE] [opportunity_id: #{args[:opportunity][:id]}, deal_id: #{hs_deal[:id]}] Deal updated succesfully"
      Rails.logger.info "[INFO] [SYNC.NETSUITE_TO_HUBSPOT.OPPORTUNITY] [COMPLETE] [opportunity_id: #{args[:opportunity][:id]}, deal_id: #{hs_deal[:id]}] Opportunity synchronized successfully"
      hs_deal
    end

    private
      def deal_filters
        [
          build_search_filter("netsuite_opportunity_id", "EQ", args[:opportunity][:id]),
          build_search_filter("pipeline", "NEQ", ENV["HUBSPOT_DEFAULT_PIPELINE"])
        ]
      end

      def payload_to_update_deal(deal_id)
        {
          deal_id: deal_id,
          "amount": args[:opportunity][:total],
          "hs_deal_stage_probability": args[:opportunity][:probability],
          # "blank": args[:opportunity][:custbody_current_stage][:refName],
          "closedate": args[:opportunity][:expectedCloseDate]
        }
      end
  end
end
