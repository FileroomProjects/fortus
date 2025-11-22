module Hubspot
  class LineItem < Hubspot::Base
    def self.create(args = {})
      client = Hubspot::Client.new(body: args)

      line_item = client.create_objects("line_items")
      line_item&.with_indifferent_access
    end
  end
end
