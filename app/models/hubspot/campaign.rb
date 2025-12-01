module Hubspot
  class Campaign < Hubspot::Base
    def self.find_by_deal_id(deal_id)
      body = { from_object_id: deal_id }
      client = Hubspot::Client.new(body: body)

      campaigns = client.fetch_object_by_associated_object_id("deals", "campaign")
      campaigns.first&.with_indifferent_access
    end
  end
end
