module Netsuite
  class Location < Netsuite::Base
    def self.find_by_subsidiary(subsidiary_id)
      client = Netsuite::Client.new({})
      results = client.fetch_locations
      location = results["items"].find { |loc| loc["subsidiary"] == subsidiary_id }
      location&.with_indifferent_access
    end
  end
end
