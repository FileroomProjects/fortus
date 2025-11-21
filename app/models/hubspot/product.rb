module Hubspot
  class Product < Hubspot::Base
    def self.create(args = {})
      @client = Hubspot::Client.new(body: args)
      if product = @client.create_product
        product = product.with_indifferent_access
      end
      product
    end

    def self.search(args = {})
      @client = Hubspot::Client.new(body: args)

      if product = @client.search_object("products")
        product = product.with_indifferent_access
      end
      product
    end
  end
end
