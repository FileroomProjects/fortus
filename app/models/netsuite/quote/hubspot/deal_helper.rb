module Netsuite::Quote::Hubspot::DealHelper
  extend ActiveSupport::Concern

  include Netsuite::Hubspot::DealHelper

  included do
    def update_hubspot_quote_deal
      hs_deal = find_deal(deal_search_filter)
      payload = payload_to_update_deal(hs_deal)
      update_deal(payload)
    end

    private
      def deal_search_filter
        [
          build_search_filter("netsuite_quote_id", "EQ", args[:estimateId]),
          build_search_filter("pipeline", "EQ", ENV["HUBSPOT_DEFAULT_PIPELINE"])
        ]
      end

      def payload_to_update_deal(hs_deal)
        {
          deal_id: hs_deal[:id],
          "amount": args[:total],
          "dealname": args[:title],
          # "terms": args[:terms],
          # "contact_display": args[:custbodyPhoneNumber],
          # "hs_latest_approval_status": args[:status]
        }
      end
  end
end
