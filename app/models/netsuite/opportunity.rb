module Netsuite
  class Opportunity < Netsuite::Base
    include Netsuite::Opportunity::Hubspot::DealHelper

    def self.create(args = {})
      client = Netsuite::Client.new(args)
      client.create_object("opportunity")
    end

    def self.update(args = {}, ns_opportunity_id)
      client = Netsuite::Client.new(args)
      client.update_object("opportunity", ns_opportunity_id)
    end

    def self.show(ns_opportunity_id)
      client = Netsuite::Client.new({})

      opportunity = client.fetch_object("opportunity", ns_opportunity_id)
      opportunity&.with_indifferent_access
    end

    def sync_opportunity_with_deal
      update_hubspot_deal
    end
  end
end
