module Netsuite::SalesOrder::Hubspot::OrderHelper
  extend ActiveSupport::Concern

  ORDER_TO_CONTACT = 507
  ORDER_TO_DEAL    = 512
  ORDER_TO_COMPANY = 509

  include Netsuite::Hubspot::OrderHelper

  included do
    def update_hubspot_order(hs_order)
      payload = prepare_payload_for_hubspot_order_update(hs_order)
      update_order(payload)
    end

    def create_hubspot_order
      payload = prepare_payload_for_hubspot_order
      create_order(payload)
    end

    def find_hubspot_order
      payload = build_search_payload(order_filters)
      Hubspot::Order.search(payload)
    end

    private
      def prepare_payload_for_hubspot_order
        {
          "properties": build_properties,
          "associations": build_associations
        }
      end

      def prepare_payload_for_hubspot_order_update(hs_order)
        {
          "properties": build_update_properties(hs_order[:id])
        }
      end

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

      def build_update_properties(hs_order_id)
        sales_order = args[:sales_order]
        {
          order_id: hs_order_id,
          "hs_external_order_status": sales_order[:orderStatus],
          "hs_total_price": sales_order[:total],
          "ship_date": sales_order[:shipDate],
          "hs_fulfillment_status": sales_order[:status],
          "hs_shipping_tracking_number": sales_order[:linkedTrackingNumbers]
          # "blank": sales_order[:custbodyrsc_freight_carrier_consid],
          # "blank": sales_order[:custbodyrsc_freight_carrier_invalidadd]
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

      def order_filters
       [ build_search_filter("netsuite_order_number", "EQ", args[:sales_order][:id]) ]
      end
  end
end
