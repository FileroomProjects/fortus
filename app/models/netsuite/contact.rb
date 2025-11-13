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
      @client.create_contact.with_indifferent_access
    end

    def self.find_by_id(args = {})
      @client = Netsuite::Client.new(args)
      @client.search_contact_by_id.with_indifferent_access
    end

     def self.find_by(args = {})
      @client = Netsuite::Client.new(args)
      @client.search_contact_by_properties.with_indifferent_access
    end
  end
end

# {
#   "firstName": "John","lastName": "Doe","email": "john.doe@example.com","jobTitle": "Sales Manager","isInactive": false,"company": { "id": 123, "type": "customer" }
# }
