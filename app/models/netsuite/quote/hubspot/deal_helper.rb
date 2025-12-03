module Netsuite::Quote::Hubspot::DealHelper
  extend ActiveSupport::Concern

  include Netsuite::Hubspot::DealHelper

  STATUS_TO_STAGE_ID = {
    "Open" => 1979552193,
    "Closed won" => 1979552198,
    "Closed Lost" => 1979552199
  }.freeze

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
          "description": args[:terms],
          "dealstage": STATUS_TO_STAGE_ID[args[:status]],
          "dealname": "#{args[:estimateId]} #{args[:title]}"
        }
      end
  end
end
