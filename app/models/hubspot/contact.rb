module Hubspot
  class Contact < Hubspot::Base
    def self.find_by_deal_id(deal_id)
      body = { deal_id: deal_id }
      @client = Hubspot::Client.new(body: body)

      if contact = @client.fetch_object_by_deal_id("contacts")
        contact = contact.with_indifferent_access
      end
      contact
    end

    def self.find_by_id(id)
      url = "/contacts/v1/contact/vid/#{id}/profile"
      @client = Hubspot::Client.new(body: {})

      if contact = @client.get_object_by_id(url)
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

    def self.search(args = {})
      @client = Hubspot::Client.new(body: args)

      if contact = @client.search_object("contacts")
        contact = contact.with_indifferent_access
      end
      contact
    end
  end
end
