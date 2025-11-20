module Netsuite::SalesOrder::Hubspot::OrderHelper
  extend ActiveSupport::Concern

  ORDER_TO_CONTACT = 507
  ORDER_TO_DEAL    = 512
  ORDER_TO_COMPANY = 509

  included do
    def prepare_payload_for_hubspot_order
      {
        "properties": build_properties,
        "associations": build_associations
      }
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
  end
end
