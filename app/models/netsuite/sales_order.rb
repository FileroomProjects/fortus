module Netsuite
  class SalesOrder < Netsuite::Base
    include Netsuite::SalesOrder::Hubspot::OrderHelper
    include Netsuite::SalesOrder::Hubspot::ContactHelper
    include Netsuite::SalesOrder::Hubspot::CompanyHelper
    include Netsuite::SalesOrder::Hubspot::DealHelper
    include Netsuite::SalesOrder::Hubspot::ProductHelper

    def sync_sales_order_with_hubspot
      find_associated_hubspot_records
      hs_order = find_hubspot_order
      if hs_order.present? && hs_order[:id].present?
        hs_order = update_hubspot_order(hs_order)
        Rails.logger.info "************** Updated Hubspot Order with ID #{hs_order[:id]}" if hs_order[:id].present?
      else
        hs_order = create_hubspot_order
        if hs_order.present? && hs_order[:id].present?
          Rails.logger.info "************** Created Hubspot Order with ID #{hs_order[:id]}"
          create_and_update_product_and_line_items_in_hubspot_order(hs_order)
        else
          raise "Failed to create Hubspot Order"
        end
      end
      update_parent_and_child_deal
    end

    def find_associated_hubspot_records
      @hs_contact = find_hubspot_contact
      @hs_company = find_hubspot_company
      @hs_parent_deal = find_deal("NEQ", "parent")
      @hs_child_deal = find_deal("EQ", "child")
    end
  end
end
