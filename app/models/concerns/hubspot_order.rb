module HubspotOrder
  extend ActiveSupport::Concern

  included do
    def find_hs_order(filters)
      payload = build_search_payload(filters)
      order = Hubspot::Order.search(payload)

      if object_present_with_id?(order)
        Rails.logger.info "[INFO] [API.HUBSPOT.ORDER] [SEARCH] [order_id: #{order[:id]}] HubSpot order found"
        order
      else
        Rails.logger.info "[INFO] [API.HUBSPOT.ORDER] [SEARCH] [filters: #{filters}] HubSpot order not found"
        nil
      end
    end

    def update_hs_order(payload)
      updated_order = Hubspot::Order.update(payload)
      process_response("Hubspot Order", "updated", updated_order)
    end

    def create_hs_order(payload)
      order = Hubspot::Order.create(payload)
      process_response("Hubspot Order", "created", order)
    end
  end
end
