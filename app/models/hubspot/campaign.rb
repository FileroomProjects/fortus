module Hubspot
  class Campaign < Hubspot::Base
    def self.find_by_deal_id(deal_id)
      body = { deal_id: deal_id }
      client = Hubspot::Client.new(body: body)

      campaign = client.fetch_object_by_deal_id("campaign")
      campaign&.with_indifferent_access
    end
  end
end
