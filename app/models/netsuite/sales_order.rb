module Netsuite
  class SalesOrder < Netsuite::Base
    include Netsuite::SalesOrder::Hubspot::BaseHelper

    def sync_sales_order_with_hubspot
      find_associated_hubspot_records
      hs_order = find_hubspot_order
      if object_present_with_id?(hs_order)
        hs_order = update_hubspot_order(hs_order)
        update_parent_deal if object_present_with_id?(hs_order)
      else
        hs_order = create_hubspot_order
        update_parent_and_child_deal
      end
      sync_line_items_in_hubspot_order(hs_order) if object_present_with_id?(hs_order)
    end

    def find_associated_hubspot_records
      @hs_contact = find_hubspot_contact
      @hs_company = find_hubspot_company
      @hs_parent_deal = find_hubspot_deal("NEQ")
      @hs_child_deal = find_hubspot_deal("EQ")
    end
  end
end
