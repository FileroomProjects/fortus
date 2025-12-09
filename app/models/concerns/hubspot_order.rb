module HubspotOrder
  extend ActiveSupport::Concern

  included do
    # Update a HubSpot order with the given payload.
    def update_hs_order(payload)
      updated_order = Hubspot::Order.update(payload)
      process_response("Hubspot Order", "update", updated_order)
    end

    # Create a new HubSpot order using the provided payload.
    def create_hs_order(payload)
      order = Hubspot::Order.create(payload)
      process_response("Hubspot Order", "create", order)
    end
  end
end
