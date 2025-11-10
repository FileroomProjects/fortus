module Hubspot
  class Contact < Hubspot::Base
    def self.find_by_deal_id(deal_id)
      body = { deal_id: deal_id }
      @client = Hubspot::Client.new(body: body)

      if contact = @client.fetch_contact_by_deal
        contact = contact.with_indifferent_access
      end
      contact
    end

    def self.find_by_id(id)
      body = { id: id }
      @client = Hubspot::Client.new(body: body)

      if contact = @client.fetch_contact_by_id
        contact = contact.with_indifferent_access
      end
      contact
    end

    def self.update(args = {})
      @client = Hubspot::Client.new(body: args)

      if contact = @client.update_contact
        contact = contact.with_indifferent_access
      end
      contact
    end
  end
end
