module Netsuite
  class SalesOrder < Netsuite::Base
    include Netsuite::SalesOrder::Hubspot::OrderHelper
    include Netsuite::SalesOrder::Hubspot::ContactHelper
    include Netsuite::SalesOrder::Hubspot::CompanyHelper
    include Netsuite::SalesOrder::Hubspot::DealHelper
    include Netsuite::SalesOrder::Hubspot::ProductHelper

    def sync_sales_order_with_hubspot
      fetch_associated_hubspot_records
      @payload = prepare_payload_for_hubspot_order
      hs_order = ::Hubspot::Order.create(@payload)
      if hs_order.present? && hs_order[:id].present?
        Rails.logger.info "************** Created Hubspot Order with ID #{hs_order[:id]}"
        create_product_and_line_items_in_hubspot_order(hs_order)
        update_parent_and_child_deal
      else
        raise "Failed to create Hubspot Order"
      end
    end

    def fetch_associated_hubspot_records
      @hs_contact = fetch_hubspot_contact
      @hs_company = fetch_hubspot_company
      @hs_parent_deal = fetch_deal("NEQ", "parent")
      @hs_child_deal = fetch_deal("EQ", "child")
    end
  end
end
