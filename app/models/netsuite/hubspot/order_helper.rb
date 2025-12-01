module Netsuite::Hubspot::OrderHelper
  extend ActiveSupport::Concern

  included do
    def update_order(payload)
      updated_order = ::Hubspot::Order.update(payload)

      if object_present_with_id?(updated_order)
        Rails.logger.info "************** Updated Hubspot Order with ID #{updated_order[:id]}"
      else
        Rails.logger.warn "************** Failed to update Hubspot Order"
      end

      updated_order
    end

    def create_order(payload)
      hs_order = ::Hubspot::Order.create(payload)

      raise "Failed to create Hubspot Order" unless object_present_with_id?(hs_order)

      Rails.logger.info "************** Created Hubspot Order with ID #{hs_order[:id]}"
      hs_order
    end
  end
end
