module Netsuite::SalesOrder::Hubspot::DealHelper
  extend ActiveSupport::Concern

  included do
    def find_hubspot_deal(operator)
      filters = build_filters(operator)
      find_hs_deal(filters)
    end

    def update_parent_and_child_deal
      update_parent_deal
      update_child_deal
    end

    def update_parent_deal
      Rails.logger.info "[INFO] [SYNC.NETSUITE_TO_HUBSPOT.OPPORTUNITY] [START] [opportunity_id: #{args[:opportunity][:id]}] Initiating opportunity synchronization"
      payload = payload_to_update_parent_deal
      hs_deal = update_hs_deal(payload)
      Rails.logger.info "[INFO] [SYNC.NETSUITE_TO_HUBSPOT.OPPORTUNITY] [UPDATE] [opportunity_id: #{args[:opportunity][:id]}, deal_id: #{hs_deal[:id]}] Deal updated successfully"
      Rails.logger.info "[INFO] [SYNC.NETSUITE_TO_HUBSPOT.OPPORTUNITY] [COMPLETE] [opportunity_id: #{args[:opportunity][:id]}, deal_id: #{hs_deal[:id]}] Opportunity synchronized successfully"
      hs_deal
    end

    def update_child_deal
      payload = payload_to_update_child_deal
      update_hs_deal(payload)
    end

    private
      def build_filters(operator)
        [
          build_search_filter("netsuite_opportunity_id", "EQ", args[:opportunity][:id]),
          build_search_filter("pipeline", operator, ENV["HUBSPOT_DEFAULT_PIPELINE"])
        ]
      end

      def payload_to_update_child_deal
        {
          deal_id: @hs_child_deal[:id],
          "dealstage": "1979552198"
        }
      end

      def payload_to_update_parent_deal
        {
          deal_id: @hs_parent_deal[:id],
          "hs_latest_approval_status": args[:opportunity][:status],
          "amount": args[:opportunity][:total]
        }
      end
  end
end
