module Hubspot
  class Contact < Hubspot::Base
    def self.find_by_deal_id(deal_id)
      body = { deal_id: deal_id }
      client = Hubspot::Client.new(body: body)

      contacts = client.fetch_object_by_deal_id("contacts")

      primary_contact = contacts.find do |contact|
        contact["associationTypes"].any? { |a| a["label"] == "Primary Contact" }
      end

      # if primary contact not present select defualt one
      selected_contact = primary_contact || contacts.first

      selected_contact&.with_indifferent_access
    end

    def self.find_by_id(id)
      url = "/contacts/v1/contact/vid/#{id}/profile"
      client = Hubspot::Client.new(body: {})

      contact = client.get_object_by_id(url)
      contact&.with_indifferent_access
    end

    def self.update(args = {})
      client = Hubspot::Client.new(body: args)

      contact = client.update_contact
      contact&.with_indifferent_access
    end

    def self.search(args = {})
      client = Hubspot::Client.new(body: args)

      contact = client.search_object("contacts")
      contact&.with_indifferent_access
    end
  end
end
