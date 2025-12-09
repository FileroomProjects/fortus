module Netsuite::SalesOrder::Hubspot::OrderHelper
  extend ActiveSupport::Concern

  ORDER_TO_CONTACT = 507
  ORDER_TO_DEAL    = 512
  ORDER_TO_COMPANY = 509

  included do
    def update_or_create_hubspot_order
      Rails.logger.info "[INFO] [SYNC.NETSUITE_TO_HUBSPOT.SALES_ORDER] [START] [sales_order_id: #{args[:sales_order][:id]}] Initiating sales order synchronization"
      hs_order = find_hubspot_order
      return update_hubspot_order(hs_order) if object_present_with_id?(hs_order)

      created_order = create_hubspot_order
      created_order
    end

    def update_hubspot_order(hs_order)
      payload = prepare_payload_for_hubspot_order_update(hs_order)
      hs_order = update_hs_order(payload)
      Rails.logger.info "[INFO] [SYNC.NETSUITE_TO_HUBSPOT.SALES_ORDER] [UPDATE] [sales_order_id: #{args[:sales_order][:id]}, order_id: #{hs_order[:id]}] Order updated succesfully"
      Rails.logger.info "[INFO] [SYNC.NETSUITE_TO_HUBSPOT.SALES_ORDER] [COMPLETE] [sales_order_id: #{args[:sales_order][:id]}, order_id: #{hs_order[:id]}] Sales Order synchronized successfully"
      hs_order
    end

    def create_hubspot_order
      payload = prepare_payload_for_hubspot_order
      hs_order = create_hs_order(payload)
      Rails.logger.info "[INFO] [SYNC.NETSUITE_TO_HUBSPOT.SALES_ORDER] [CREATE] [sales_order_id: #{args[:sales_order][:id]}, order_id: #{hs_order[:id]}] Order created succesfully"
      Rails.logger.info "[INFO] [SYNC.NETSUITE_TO_HUBSPOT.SALES_ORDER] [COMPLETE] [sales_order_id: #{args[:sales_order][:id]}, order_id: #{hs_order[:id]}] Sales Order synchronized successfully"
      hs_order
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
          "hs_order_name": sales_order[:title],
          "hs_external_order_status": sales_order[:status],
          "hs_total_price": sales_order[:total],
          # "blank": sales_order[:shipDate],
          "hs_external_created_date": sales_order[:tranDate],
          "hs_fulfillment_status": sales_order[:status],
          # "blank": sales_order[:deliveryDate],
          "hs_shipping_tracking_number": sales_order[:trackingNumbers] # tracking Numbers
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
