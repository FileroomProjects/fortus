module Netsuite::SalesOrder::Hubspot::DealHelper
  extend ActiveSupport::Concern

  included do
    def find_hubspot_deal(operator)
      filters = build_filters(operator)
      find_hs_deal(filters)
    end

    def update_parent_and_child_deal
      update_hubspot_deal(@hs_parent_deal[:id])
      update_hubspot_deal(@hs_child_deal[:id])
    end

    def update_parent_deal
      payload = payload_to_update_parent_deal(@hs_parent_deal[:id])
      update_hs_deal(payload)
    end

    private
      def update_hubspot_deal(deal_id)
        payload = payload_to_update_deal(deal_id)
        update_hs_deal(payload)
      end

      def build_filters(operator)
        [
          build_search_filter("netsuite_opportunity_id", "EQ", args[:opportunity][:id]),
          build_search_filter("pipeline", operator, ENV["HUBSPOT_DEFAULT_PIPELINE"])
        ]
      end

      def payload_to_update_deal(deal_id)
        {
          deal_id: deal_id,
          "dealstage": "closedwon"
        }
      end

      def payload_to_update_parent_deal(deal_id)
        {
          deal_id: deal_id,
          "hs_latest_approval_status": args[:opportunity][:status],
          "amount": args[:opportunity][:total]
        }
      end
  end
end
