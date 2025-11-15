module Hubspot
  class Campaign < Hubspot::Base
    def self.find_by_deal_id(deal_id)
      body = { deal_id: deal_id }
      @client = Hubspot::Client.new(body: body)

      if campaign = @client.fetch_campaign_by_deal
        campaign = campaign.with_indifferent_access
      end
      campaign
    end
  end
end
