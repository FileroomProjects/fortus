module Netsuite::SalesOrder::Hubspot::LineItemHelper
  extend ActiveSupport::Concern

  included do
    def sync_line_items_in_hubspot_order(hs_order)
      sync_line_items(hs_order, "orders", "line_item_to_order")
    end
  end
end
