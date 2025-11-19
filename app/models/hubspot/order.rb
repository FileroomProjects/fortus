module Hubspot
  class Order < Hubspot::Base
    def self.create(args = {})
      @client = Hubspot::Client.new(body: args)
      if order = @client.create_order
        order = order.with_indifferent_access
      end
      order
    end
  end
end
