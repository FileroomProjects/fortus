module Netsuite::Estimate::Hubspot::DealHelper
  extend ActiveSupport::Concern

  STATUS_TO_STAGE_ID = {
    "10" => 1979552193, # Open
    "14" => 1979552199 # Closed Lost
  }.freeze


  DEAL_TO_CONTACT = 3
  DEAL_TO_COMPANY = 5
  DEAL_TO_DEAL = 451

  included do
    def update_or_create_hubspot_child_deal
      existing_deal = find_hubspot_child_deal

      return update_hubspot_child_deal(existing_deal) if object_present_with_id?(existing_deal)

      if args[:opportunity][:id].present?
        @hs_parent_deal = find_hubspot_parent_deal
      end

      create_hubspot_child_deal
    end

    def find_hubspot_child_deal
      find_hs_deal(child_deal_search_filter, raise_error: false)
    end

    def find_hubspot_parent_deal
      find_hs_deal(parent_deal_search_filter, raise_error: false)
    end

    def update_hubspot_child_deal(hs_deal)
      update_hs_deal(payload_to_update_deal(hs_deal))
    end

    def create_hubspot_child_deal
      create_hs_deal(payload_to_create_deal)
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
          "dealstage": STATUS_TO_STAGE_ID[args[:status]],
          "dealname": "#{args[:estimateId]} #{args[:title]}"
        }
      end

      def payload_to_create_deal
        {
          properties: base_properties.merge(optional_property),
          associations: associations_list
        }
      end

      def base_properties
        {
          "dealname": deal_name,
          "pipeline": ENV["HUBSPOT_DEFAULT_PIPELINE"],
          "dealstage": STATUS_TO_STAGE_ID[args[:status]],
          "netsuite_quote_id": args[:estimateId],
          "amount": args[:total],
          "netsuite_location": netsuite_estimate_location(args[:estimateId]),
          "netsuite_origin": "netsuite",
          "is_child": "true"
        }
      end

      def optional_property
        return {} unless args[:opportunity].present?

        { "netsuite_opportunity_id": args[:opportunity][:id] }
      end

      def associations_list
        list = [
          association(@hs_contact[:id], DEAL_TO_CONTACT),
          association(@hs_company[:id], DEAL_TO_COMPANY)
        ]

        list << association(@hs_parent_deal[:id], DEAL_TO_DEAL) if @hs_parent_deal.present?
        list
      end

      def deal_name
        "#{args[:estimateId]} #{args[:title]}"
      end
  end
end
