module Netsuite::SalesOrder::Hubspot::OrderHelper
  extend ActiveSupport::Concern

  ORDER_TO_CONTACT = 507
  ORDER_TO_DEAL    = 512
  ORDER_TO_COMPANY = 509

  included do
    def update_hubspot_order(hs_order)
      payload = prepare_payload_for_hubspot_order_update(hs_order)
      hs_order = ::Hubspot::Order.update(payload)
      hs_order
    end

    def create_hubspot_order
      payload = prepare_payload_for_hubspot_order
      hs_order = ::Hubspot::Order.create(payload)
      hs_order
    end

    def prepare_payload_for_hubspot_order
      {
        "properties": build_properties,
        "associations": build_associations
      }
    end

    def prepare_payload_for_hubspot_order_update(hs_order)
      {
        "properties": build_properties.merge(order_id: hs_order[:id])
      }
    end

    def find_hubspot_order
      Hubspot::Order.search(payload_for_search_hubspot_order)
    end

    private
      def build_properties
        sales_order = args[:sales_order]
        {
          "hs_order_name": sales_order[:title],
          "hs_external_created_date": sales_order[:trandate],
          "netsuite_order_number": sales_order[:id],
          "hs_total_price": sales_order[:total],
          "hs_currency_code": "AUD"
        }
      end

      def build_associations
        [
          association(@hs_contact[:id], ORDER_TO_CONTACT),
          association(@hs_parent_deal[:id], ORDER_TO_DEAL),
          association(@hs_child_deal[:id], ORDER_TO_DEAL),
          association(@hs_company[:id], ORDER_TO_COMPANY)
        ]
      end

      def association(target_id, type_id)
        {
          to: { id: target_id },
          types: [
            {
              associationCategory: "HUBSPOT_DEFINED",
              associationTypeId: type_id
            }
          ]
        }
      end

      def payload_for_search_hubspot_order
        {
          filterGroups: [
            {
              filters: [
                {
                  propertyName: "netsuite_order_number",
                  operator: "EQ",
                  value: args[:sales_order][:id]
                }
              ]
            }
          ]
        }
      end
  end
end
