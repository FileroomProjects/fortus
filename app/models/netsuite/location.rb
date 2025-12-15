module Netsuite
  class Location < Netsuite::Base
    def self.find_by_subsidiary(subsidiary_id)
      client = Netsuite::Client.new({})
      results = client.fetch_locations_by_subsidiary(subsidiary_id)
      location = results["items"].first
      location&.with_indifferent_access
    end
  end
end
