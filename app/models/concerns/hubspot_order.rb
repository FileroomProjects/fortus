module HubspotOrder
  extend ActiveSupport::Concern

  included do
    def find_hs_order(filters)
      payload = build_search_payload(filters)
      order = Hubspot::Order.search(payload)

      if object_present_with_id?(order)
        Rails.logger.info "[INFO] [API.HUBSPOT.ORDER] [SEARCH] [order_id: #{order[:id]}] HubSpot order found"
        return order
      end

      Rails.logger.info "[INFO] [API.HUBSPOT.ORDER] [SEARCH] [filters: #{filters}] HubSpot order not found"
      nil
    end

    def update_hs_order(payload)
      updated_order = Hubspot::Order.update(payload)
      process_response("Hubspot Order", "updated", updated_order)
    end

    # Create a new HubSpot order using the provided payload.
    def create_hs_order(payload)
      order = Hubspot::Order.create(payload)
      process_response("Hubspot Order", "created", order)
    end

    def hs_order_sync_success_log(order, action, ns_sales_order_id)
      Rails.logger.info "[INFO] [SYNC.NETSUITE_TO_HUBSPOT.SALES_ORDER] [#{action}] [sales_order_id: #{ns_sales_order_id}, order_id: #{order[:id]}] Order #{action.downcase}d succesfully"
      Rails.logger.info "[INFO] [SYNC.NETSUITE_TO_HUBSPOT.SALES_ORDER] [COMPLETE] [sales_order_id: #{ns_sales_order_id}, order_id: #{order[:id]}] Sales Order synchronized successfully"
      order
    end
  end
end
