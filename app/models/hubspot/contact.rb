module Hubspot
  class Contact < Hubspot::Base
    
    def self.find_by_deal_id(deal_id)
      body = {deal_id: deal_id}
      @client = Hubspot::Client.new(body: body)

      if contact = @client.fetch_contact
        contact = contact.with_indifferent_access
      end
      contact
    end
  end
end
