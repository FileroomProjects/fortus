module HubspotOrder
  extend ActiveSupport::Concern

  included do
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
