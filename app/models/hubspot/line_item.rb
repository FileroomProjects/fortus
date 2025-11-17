module Hubspot
  class LineItem < Hubspot::Base
    def self.create(args = {})
      @client = Hubspot::Client.new(body: args)
      if line_item = @client.create_line_item
        line_item = line_item.with_indifferent_access
      end
      line_item
    end
  end
end
