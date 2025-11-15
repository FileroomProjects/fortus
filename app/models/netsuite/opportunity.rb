module Netsuite
  class Opportunity
    def self.create(args = {})
      @client = Netsuite::Client.new(args)
      @client.create_opportunity
    end
  end
end
