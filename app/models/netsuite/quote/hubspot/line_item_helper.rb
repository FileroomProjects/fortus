module Netsuite::Quote::Hubspot::LineItemHelper
  extend ActiveSupport::Concern

  include Netsuite::Hubspot::LineItemHelper

  included do
    def sync_line_items_in_hubspot_quote_deal(hs_deal)
      sync_line_items(hs_deal, "deals", "line_item_to_deal")
    end
  end
end
