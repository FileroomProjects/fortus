module Hubspot
  class LineItem < Hubspot::Base
    def self.create(args = {})
      client = Hubspot::Client.new(body: args)

      line_item = client.create_objects("line_items")
      line_item&.with_indifferent_access
    end

    def self.search(args = {})
      client = Hubspot::Client.new(body: args)

      contact = client.search_object("line_items")
      contact&.with_indifferent_access
    end

    def self.find_by_object_id(object_id, object_type)
      body = { from_object_id: object_id }
      client = Hubspot::Client.new(body: body)

      line_items = client.fetch_object_by_associated_object_id(object_type, "line_items")
      line_items.first&.with_indifferent_access[:results]
    end

    def self.update(line_item_id, body)
      client = Hubspot::Client.new(body: {})

      line_item = client.update_object("line_items/#{line_item_id}", body)
      line_item&.with_indifferent_access
    end

    def self.find_by_id(id)
      url = "/crm/v3/objects/line_items/#{id}?properties=netsuite_item_id,amount,quantity"
      client = Hubspot::Client.new(body: {})

      line_items = client.get_object_by_id(url)
      line_items&.with_indifferent_access
    end

    def self.remove_line_item_association(line_item_id, from_object_id, from_object_type)
      client = Hubspot::Client.new(body: {})

      url = "/crm/v4/objects/#{from_object_type}/#{from_object_id}/associations/line_items/#{line_item_id}"
      response = client.remove_association(url)
      response
    end

    def self.associate_line_item(body, object_type)
      client = Hubspot::Client.new(body: body)
      client.create_association("line_items", object_type)
    end
  end
end
