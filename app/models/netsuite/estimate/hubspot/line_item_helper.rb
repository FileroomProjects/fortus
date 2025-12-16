module Netsuite::Estimate::Hubspot::LineItemHelper
  extend ActiveSupport::Concern

  included do
    def sync_line_items_in_hubspot_child_deal(hs_deal)
      sync_line_items(hs_deal, "deals", "line_item_to_deal")
    end
  end
end
