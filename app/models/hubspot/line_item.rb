module Hubspot
  class LineItem < Hubspot::Base
    def self.create(args = {})
      @client = Hubspot::Client.new(body: args)
      if line_item = @client.create_objects("line_items")
        line_item = line_item.with_indifferent_access
      end
      line_item
    end
  end
end
