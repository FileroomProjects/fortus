module Hubspot::Deal::HubspotChildDealHelper
  extend ActiveSupport::Concern

  included do
    def create_hubspot_child_deal(ns_estimate)
      create_child_deal_with(:regular, ns_estimate)
    end

    def create_duplicate_hubspot_child_deal(ns_estimate)
      create_child_deal_with(:duplicate, ns_estimate)
    end

    def find_parent_deal
      filters = deal_filters("NEQ")
      find_hs_deal(filters)
    end

    def association_for_deal(hs_child_deal_id, parent_deal_id, ns_estimate_id)
      info_log("Associating Child Deal with Company, Contact, Parent Deal and Line Item")
      hs_deal = Hubspot::ChildDeal.new(hs_child_deal_id, parent_deal_id, ns_estimate_id)
      hs_deal.associate_company
      hs_deal.associate_contact
      hs_deal.associate_parent_deal
      hs_deal.associate_line_items
    end

    private
      def create_child_deal_with(type, ns_estimate)
        payload = child_deal_payload(type, ns_estimate[:id])
        create_hs_deal(payload)
      end

      def child_deal_payload(type, ns_estimate_id)
        dealname = build_dealname(type, ns_estimate_id)

        {
          "properties": {
            "dealname": dealname,
            "pipeline": ENV["HUBSPOT_DEFAULT_PIPELINE"],
            "dealstage": ENV["HUBSPOT_DEFAULT_DEALSTAGE"],
            "netsuite_quote_id": ns_estimate_id,
            "amount": fetch_prop_field(:amount),
            "netsuite_location": netsuite_estimate_location(ns_estimate_id),
            "netsuite_origin": "netsuite",
            "netsuite_opportunity_id": @netsuite_opportunity_id,
            "is_child": "true"
          }
        }
      end

      def deal_filters(operator)
        [
          build_search_filter("netsuite_opportunity_id", "EQ", @netsuite_opportunity_id),
          build_search_filter("pipeline", operator, ENV["HUBSPOT_DEFAULT_PIPELINE"])
        ]
      end

      def build_dealname(type, ns_estimate_id)
        base_dealname = fetch_prop_field(:dealname)

        case type
        when :regular
          "#{ns_estimate_id} #{base_dealname}"
        when :duplicate
          suffix = base_dealname.split(" ", 2)[1]
          "#{ns_estimate_id} #{suffix}"
        end
      end
  end
end
