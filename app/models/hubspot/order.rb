module Hubspot
  class Order < Hubspot::Base
    def self.create(args = {})
      client = Hubspot::Client.new(body: args)
      order = client.create_objects("orders")
      order&.with_indifferent_access
    end

    def self.search(args = {})
      client = Hubspot::Client.new(body: args)

      order = client.search_object("orders")
      order&.with_indifferent_access
    end

    def self.update(args = {})
      client = Hubspot::Client.new(body: args)
      order = client.update_order
      order&.with_indifferent_access
    end
  end
end
