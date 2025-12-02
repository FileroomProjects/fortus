module Hubspot
  class Contact < Hubspot::Base
    def self.find_by_deal_id(deal_id)
      client = Hubspot::Client.new(body: { from_object_id: deal_id })
      contacts = client.fetch_object_by_associated_object_id("deals", "contacts")

      return nil unless contacts.present?

      selected = selected_contact(contacts)
      selected&.with_indifferent_access
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

    private
      def self.selected_contact(contacts)
        primary_contact = contacts.find do |contact|
          contact["associationTypes"].any? { |a| a["label"] == "Primary Contact" }
        end

        primary_contact || contacts.first
      end
  end
end
