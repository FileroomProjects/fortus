module Netsuite::Estimate::Hubspot::ChildDealHelper
  extend ActiveSupport::Concern

  STATUS_TO_STAGE_ID = {
    "10" => Hubspot::Constants::NETSUITE_QUOTE_OPEN_STAGE,
    "14" => Hubspot::Constants::NETSUITE_QUOTE_CLOSED_LOST_STAGE
  }.freeze

  included do
    # Ensure a HubSpot child deal exists for this NetSuite estimate.
    # If a matching HS child deal exists, update it; otherwise create a new one.
    def update_or_create_hubspot_child_deal
      existing_deal = find_hubspot_child_deal

      return update_hubspot_child_deal(existing_deal) if object_present_with_id?(existing_deal)

      create_hubspot_child_deal
    end

    # Search for an existing HubSpot child deal using NetSuite estimate id and pipeline.
    # Returns the found deal object or nil (does not raise when not found).
    def find_hubspot_child_deal
      find_hs_deal(child_deal_search_filter, raise_error: false)
    end

    # Update an existing HubSpot child deal.
    def update_hubspot_child_deal(hs_deal)
      update_hs_deal(payload_to_update_deal(hs_deal))
    end

    # Create a new HubSpot child deal with properties and associations based on the NetSuite estimate.
    def create_hubspot_child_deal
      create_hs_deal(payload_to_create_child_deal)
    end

    private
      def child_deal_search_filter
        [
          build_search_filter("netsuite_quote_id", "EQ", args[:estimateId]),
          build_search_filter("pipeline", "EQ", Hubspot::Constants::NETSUITE_QUOTE_PIPELINE)
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

      def payload_to_create_child_deal
        {
          properties: child_deal_base_properties.merge(optional_property),
          associations: child_deal_associations_list
        }
      end

      def child_deal_base_properties
        {
          "dealname": deal_name,
          "pipeline": Hubspot::Constants::NETSUITE_QUOTE_PIPELINE,
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

      def child_deal_associations_list
        list = [
          association(@hs_contact[:id], Hubspot::Constants::DEAL_TO_CONTACT),
          association(@hs_company[:id], Hubspot::Constants::DEAL_TO_COMPANY)
        ]

        list << association(@hs_parent_deal[:id], Hubspot::Constants::DEAL_TO_DEAL) if @hs_parent_deal.present?
        list
      end

      def deal_name
        "#{args[:estimateId]} #{args[:title]}"
      end
  end
end
