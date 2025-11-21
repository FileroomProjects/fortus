# {
#   "firstName": "John",
#   "lastName": "Doe",
#   "email": "john.doe@example.com",
#   "jobTitle": "Sales Manager",
#   "isInactive": false,
#   "company": { "id": 123, "type": "customer" }
# }
module Netsuite
  class Contact
    def self.create(args = {})
      @client = Netsuite::Client.new(args)
      contact = @client.create_contact
      if contact.present?
        contact = contact.with_indifferent_access
      end
      contact
    end

    def self.find_by_id(args = {})
      @client = Netsuite::Client.new(args)
      contact = @client.search_contact_by_id
      if contact.present?
        contact = contact.with_indifferent_access
      end
      contact
    end

    def self.find_by(args = {})
      @client = Netsuite::Client.new(args)
      contact = @client.search_contact_by_properties
      if contact.present?
        contact = contact.with_indifferent_access
      end
      contact
    end
  end
end

# {
#   "firstName": "John","lastName": "Doe","email": "john.doe@example.com","jobTitle": "Sales Manager","isInactive": false,"company": { "id": 123, "type": "customer" }
# }
