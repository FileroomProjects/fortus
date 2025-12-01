module Netsuite::Opportunity::Hubspot::DealHelper
  extend ActiveSupport::Concern

  include Netsuite::Hubspot::DealHelper

  included do
    def update_hubspot_deal
      hs_deal = find_deal(filters)
      payload = payload_to_update_deal(hs_deal[:id])
      update_deal(payload)
    end

    private
      def filters
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
