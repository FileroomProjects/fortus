module Netsuite
  class Opportunity
    def self.create(args = {})
      client = Netsuite::Client.new(args)
      client.create_opportunity
    end

    def self.show(ns_opportunity_id)
      client = Netsuite::Client.new({})
      opportunity = client.fetch_object("opportunity/#{ns_opportunity_id}")
      opportunity&.with_indifferent_access
    end
  end
end
