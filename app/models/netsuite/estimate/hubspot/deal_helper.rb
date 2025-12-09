module Netsuite::Estimate::Hubspot::DealHelper
  extend ActiveSupport::Concern

  STATUS_TO_STAGE_ID = {
    "10" => 1979552193, # Open
    "14" => 1979552199 # Closed Lost
  }.freeze

  included do
    def find_or_create_hubspot_parent_deal
      return nil unless args[:opportunity].present?

      hs_deal = find_hubspot_parent_deal

      return hs_deal if object_present_with_id?(hs_deal)

      create_hubspot_parent_deal
    end

    def find_hubspot_parent_deal
      find_hs_deal(parent_deal_search_filter, raise_error: false)
    end

    def create_hubspot_parent_deal
      create_hs_deal(payload_to_create_parent_deal)
    end

    private
      def parent_deal_search_filter
        [
          build_search_filter("netsuite_opportunity_id", "EQ", args[:opportunity][:id]),
          build_search_filter("pipeline", "NEQ", Hubspot::Constants::NETSUITE_QUOTE_PIPELINE)
        ]
      end

      def payload_to_create_parent_deal
        {
          properties: parent_deal_base_properties.merge(optional_property),
          associations: child_deal_associations_list
        }
      end

      def parent_deal_base_properties
        {
          "dealname": args[:opportunity][:title],
          "pipeline": Hubspot::Constants::SALES_TEAM_PIPELINE,
          "dealstage": Hubspot::Constants::SALES_TEAM_INTRODUCTION_STAGE,
          "netsuite_opportunity_id": args[:opportunity][:id],
          "amount": args[:opportunity][:projectedTotal],
          "closedate": args[:opportunity][:expectedClose],
          "request_quote_notes": args[:opportunity][:requestQuoteNotes],
          "request_quote_triggered": args[:opportunity][:requestQuoteTriggered]
        }
      end

      def child_deal_associations_list
        association(@hs_contact[:id], Hubspot::Constants::DEAL_TO_CONTACT)
        association(@hs_company[:id], Hubspot::Constants::DEAL_TO_COMPANY)
      end
  end
end
