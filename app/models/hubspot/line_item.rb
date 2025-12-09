module Hubspot
  class LineItem < Hubspot::Base
    def self.create(args = {})
      # Create a HubSpot line item using the provided payload.
      client = Hubspot::Client.new(body: args)

      line_item = client.create_objects("line_items")
      line_item&.with_indifferent_access
    end

    def self.search(args = {})
      # Search HubSpot line items and return the first match.
      client = Hubspot::Client.new(body: args)

      contact = client.search_object("line_items")
      contact&.with_indifferent_access
    end

    def self.find_by_object_id(object_id, object_type)
      # Fetch line items associated with an object (deal/order) and return raw results.
      body = { from_object_id: object_id }
      client = Hubspot::Client.new(body: body)

      client.fetch_object_by_associated_object_id(object_type, "line_items")
    end

    def self.update(line_item_id, body)
      # Update an existing HubSpot line item and return updated object.
      client = Hubspot::Client.new(body: {})

      line_item = client.update_object("line_items/#{line_item_id}", body)
      line_item&.with_indifferent_access
    end

    def self.find_by_id(id)
      # Retrieve a line item by id and include netsuite fields.
      url = "/crm/v3/objects/line_items/#{id}?properties=netsuite_item_id,amount,quantity"
      client = Hubspot::Client.new(body: {})

      line_items = client.get_object_by_id(url)
      line_items&.with_indifferent_access
    end

    def self.remove_line_item_association(line_item_id, from_object_id, from_object_type)
      # Remove the association between a line item and an object; returns client response.
      client = Hubspot::Client.new(body: {})

      url = "/crm/v4/objects/#{from_object_type}/#{from_object_id}/associations/line_items/#{line_item_id}"
      response = client.remove_association(url)
      response
    end

    def self.associate_line_item(body, object_type)
      # Create an association between a line item and another object type.
      client = Hubspot::Client.new(body: body)
      client.create_association("line_items", object_type)
    end
  end
end
