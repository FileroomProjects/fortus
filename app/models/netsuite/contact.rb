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
    def self.create(args={})
      @client = Netsuite::Client.new(args)
      @client.create_contact
    end
  end
end

# {
#   "firstName": "John","lastName": "Doe","email": "john.doe@example.com","jobTitle": "Sales Manager","isInactive": false,"company": { "id": 123, "type": "customer" }
# }