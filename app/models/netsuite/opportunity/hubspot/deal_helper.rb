module Netsuite::Opportunity::Hubspot::DealHelper
  extend ActiveSupport::Concern

  included do
    def update_hubspot_deal
      hs_deal = find_hs_deal(deal_filters)
      payload = payload_to_update_deal(hs_deal[:id])
      update_hs_deal(payload)
    end

    private
      def deal_filters
        [
          build_search_filter("netsuite_opportunity_id", "EQ", args[:opportunity][:id]),
          build_search_filter("pipeline", "NEQ", Hubspot::Constants::NETSUITE_QUOTE_PIPELINE)
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
