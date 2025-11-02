module Hubspot
  class Company < Hubspot::Base
    
    def self.find_by_deal_id(deal_id)
      body = {"inputs": [{ "id": "#{deal_id}" }] }
      
      @client = Hubspot::Client.new(body: body)

      if company = @client.fetch_company
        company = company.first["to"]
      end
      company
    end
  end
end
