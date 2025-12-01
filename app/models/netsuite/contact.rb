module Netsuite
  class Contact
    def self.create(args = {})
      client = Netsuite::Client.new(args)
      client.create_object("contact")
    end

    def self.find_by_id(args = {})
      client = Netsuite::Client.new(args)
      contact = client.search_contact_by_id
      contact&.with_indifferent_access
    end

    def self.find_by(args = {})
      client = Netsuite::Client.new(args)
      contact = client.search_contact_by_properties
      contact&.with_indifferent_access
    end
  end
end
