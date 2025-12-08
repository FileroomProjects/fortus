module Netsuite
  class Estimate < Netsuite::Base
    # This model handles quote/estimate operations in NetSuite
    include Netsuite::Estimate::Hubspot::BaseHelper

    def self.create(args = {})
      client = Netsuite::Client.new(args)
      client.create_object("estimate")
    end

    def self.show(ns_estimate_id)
      client = Netsuite::Client.new({})
      estimate = client.fetch_object("estimate", ns_estimate_id)
      estimate&.with_indifferent_access
    end

    def self.fetch_items(ns_estimate_id)
      client = Netsuite::Client.new({})
      results = client.fetch_estimate_items(ns_estimate_id)
      items = results.dig("item", "items")
      { "items" => items }&.with_indifferent_access
    end

    def sync_ns_estimate_with_hs_child_deal
      update_or_create_associated_hubspot_records
      hs_deal = update_or_create_hubspot_child_deal
      sync_line_items_in_hubspot_child_deal(hs_deal)
    end

    def update_or_create_associated_hubspot_records
      @hs_company = update_or_create_hubspot_company
      @hs_contact = update_or_create_hubspot_contact
    end
  end
end
