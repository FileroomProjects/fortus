module Hubspot
  class Order < Hubspot::Base
    def self.create(args = {})
      # Create a HubSpot order with the provided payload.
      client = Hubspot::Client.new(body: args)

      order = client.create_objects("orders")
      order&.with_indifferent_access
    end

    def self.search(args = {})
      # Search HubSpot orders and return the first result.
      client = Hubspot::Client.new(body: args)

      order = client.search_object("orders")
      order&.with_indifferent_access
    end

    def self.update(args = {})
      # Update a HubSpot order and return the updated object.
      client = Hubspot::Client.new(body: args)

      order = client.update_order
      order&.with_indifferent_access
    end

    # Create associations from an order to another object type (e.g. deals).
    def self.create_association(body, to_object_type)
      client = Hubspot::Client.new(body: body)
      client.create_association("orders", to_object_type)
    end
  end
end
