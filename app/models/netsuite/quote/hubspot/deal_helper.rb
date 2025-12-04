module Netsuite::Quote::Hubspot::DealHelper
  extend ActiveSupport::Concern

  include Netsuite::Hubspot::DealHelper

  STATUS_TO_STAGE_ID = {
    "Open" => 1979552193,
    "Closed won" => 1979552198,
    "Closed Lost" => 1979552199
  }.freeze


  DEAL_TO_CONTACT = 3
  DEAL_TO_COMPANY = 5
  DEAL_TO_DEAL = 451

  included do
    def find_hubspot_quote_deal
      find_deal(child_deal_search_filter, raise_error: false)
    end

    def find_hubspot_parent_deal
      find_deal(parent_deal_search_filter)
    end

    def update_hubspot_quote_deal(hs_deal)
      payload = payload_to_update_deal(hs_deal)
      update_deal(payload)
    end

    def create_hubspot_quote_deal
      payload = payload_to_create_deal
      create_deal(payload)
    end

    private
      def child_deal_search_filter
        [
          build_search_filter("netsuite_quote_id", "EQ", args[:estimateId]),
          build_search_filter("pipeline", "EQ", ENV["HUBSPOT_DEFAULT_PIPELINE"])
        ]
      end

      def parent_deal_search_filter
        [
          build_search_filter("netsuite_opportunity_id", "EQ", args[:opportunity][:id]),
          build_search_filter("pipeline", "NEQ", ENV["HUBSPOT_DEFAULT_PIPELINE"])
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

      def payload_to_create_deal
        {
          "properties": build_properties,
          "associations": build_associations
        }
      end

      def build_properties
        {
          "dealname": "#{args[:estimateId]} #{args[:title]}",
          "pipeline": ENV["HUBSPOT_DEFAULT_PIPELINE"],
          "dealstage": STATUS_TO_STAGE_ID[args[:status]],
          "description": args[:terms],
          "netsuite_quote_id": args[:estimateId],
          "amount": args[:total],
          "netsuite_location": netsuite_estimate_location(args[:estimateId]),
          "netsuite_origin": "netsuite",
          "netsuite_opportunity_id": args[:opportunity][:id],
          "is_child": "true"
        }
      end

      def build_associations
        [
          association(@hs_contact[:id], DEAL_TO_CONTACT),
          association(@hs_parent_deal[:id], DEAL_TO_DEAL),
          association(@hs_company[:id], DEAL_TO_COMPANY)
        ]
      end
  end
end
