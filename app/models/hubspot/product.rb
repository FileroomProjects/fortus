module Hubspot
  class Product < Hubspot::Base
    def self.create(args = {})
      client = Hubspot::Client.new(body: args)

      product = client.create_objects("products")
      product&.with_indifferent_access
    end

    def self.search(args = {})
      client = Hubspot::Client.new(body: args)

      product = client.search_object("products")
      product&.with_indifferent_access
    end
  end
end
