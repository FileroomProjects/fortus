module Netsuite
  class Quote < Netsuite::Base
    # This model handles quote/estimate operations in NetSuite
    include Netsuite::Quote::Hubspot::BaseHelper

    def self.create(args = {})
      client = Netsuite::Client.new(args)
      client.create_object("estimate")
    end

    def self.show(ns_quote_id)
      client = Netsuite::Client.new({})
      quote = client.fetch_object("estimate", ns_quote_id)
      quote&.with_indifferent_access
    end

    def self.fetch_items(ns_quote_id)
      client = Netsuite::Client.new({})
      expanded = client.fetch_estimate_items(ns_quote_id)
      items = expanded.dig("item", "items")
      { "items" => items }
    end

    def sync_quote_estimate_with_quote_deal
      updated_hs_deal = update_hubspot_quote_deal
      sync_line_items_in_hubspot_quote_deal(updated_hs_deal)
      update_company_info
      update_contact_info
    end
  end
end
