module Netsuite
  class Location < Netsuite::Base
    # Fetches all NetSuite active locations and returns the location
    # that matches the given subsidiary ID.
    def self.find_by_subsidiary_id(subsidiary_id)
      client = Netsuite::Client.new({})
      results = client.fetch_locations

      location = results["items"].find { |loc| loc["subsidiary"] == subsidiary_id }
      location&.with_indifferent_access
    end
  end
end
