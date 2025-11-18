module Netsuite
  class Opportunity
    def self.create(args = {})
      @client = Netsuite::Client.new(args)
      @client.create_opportunity
    end

    def self.show(ns_opportunity_id)
      @client = Netsuite::Client.new({})
      if opportunity = @client.fetch_opportunity(ns_opportunity_id)
        opportunity = opportunity.with_indifferent_access
      end
      opportunity
    end
  end
end
