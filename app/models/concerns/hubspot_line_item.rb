module HubspotLineItem
  extend ActiveSupport::Concern

  included do
    # Sync HubSpot line items so they match the provided NetSuite items.
    def sync_line_items(hs_object, object_type, association_type)
      raise "Missing args or args[:items]" if args.nil? || args[:items].nil?

      # Fetch all existing HubSpot line item IDs already associated with the given object.
      existing_ids = line_item_ids_for_associated_object(hs_object[:id], object_type)

      # If there are no existing HubSpot line items:
      #  - Simply create all line items coming from NetSuite and return.
      #  - Since there are none to update or remove.
      if existing_ids.blank?
        sync_new_items(hs_object, object_type, association_type)
        return
      end

      # If existing line items are present:
      #  - For every NetSuite item:
      #  - Create it in HubSpot if it doesn't exist OR update it if already present.
      args[:items].each do |item|
        create_or_update_line_item(item, existing_ids, hs_object[:id], object_type, association_type)
      end

      # Re-fetch all HubSpot line item IDs associated with the object.
      # Prepare a list of NetSuite item IDs currently present.
      updated_ids = line_item_ids_for_associated_object(hs_object[:id], object_type)
      ns_item_ids = args[:items].map { |item| item[:itemId] }

      # Remove those HubSpot line items which are no longer present in NetSuite.
      remove_line_items(updated_ids, hs_object[:id], object_type, ns_item_ids)
    end

    def sync_new_items(hs_object, object_type, association_type)
      args[:items].each do |item|
        log_sync_start(item)

        create_and_associate_line_item(item, hs_object[:id], object_type, association_type)
      end
    end

    # Create a new HubSpot line item or update an existing one if found.
    # - item: NetSuite item hash
    # - existing_ids: Array of existing HubSpot line item IDs associated with the object
    # - object_id/object_type/association_type: used when creating and associating a new item
    def create_or_update_line_item(item, existing_ids, object_id, object_type, association_type)
      log_sync_start(item)

      filters = line_item_search_filters(item, existing_ids)
      hs_line_item = find_line_item(filters)

      if object_present_with_id?(hs_line_item)
        return update_line_item(hs_line_item[:id], item)
      end

      create_and_associate_line_item(item, object_id, object_type, association_type)
    end

    # Create a HubSpot line item from the given item data and associate it
    # with the provided HubSpot object(deal/order).
    def create_and_associate_line_item(item, object_id, object_type, association_type)
      payload = line_item_payload(item)
      hs_line_item = Hubspot::LineItem.create(payload)
      process_response("Hubspot Line Item", "create", hs_line_item)

      Rails.logger.info "[INFO] [SYNC.NETSUITE_TO_HUBSPOT.ITEM] [CREATE] [item_id: #{item[:itemId]}, line_item_id: #{hs_line_item[:id]}] Hubspot line item created"
      Rails.logger.info "[INFO] [SYNC.NETSUITE_TO_HUBSPOT.ITEM] [COMPLETE] [item_id: #{item[:itemId]}, line_item_id: #{hs_line_item[:id]}] Netsuite item synchronized successfully"

      associate_line_item(hs_line_item[:id], object_id, object_type, association_type)
    end

    # Find a HubSpot line item using the provided search filters.
    # Returns the search result (may be nil/empty) and does not raise on not found.
    def find_line_item(filters)
      payload = build_search_payload(filters)
      hs_line_item = Hubspot::LineItem.search(payload)
      if object_present_with_id?(hs_line_item)
        Rails.logger.info "[INFO] [API.HUBSPOT.LINE_ITEM] [SEARCH] [line_item_id: #{hs_line_item[:id]}] HubSpot line item found"
        return hs_line_item
      end

      Rails.logger.info "[INFO] [API.HUBSPOT.LINE_ITEM] [SEARCH] [filters: #{filters}] HubSpot line item not found"
      nil
    end

    def update_line_item(line_item_id, item)
      payload = line_item_payload(item)
      hs_line_item = Hubspot::LineItem.update(line_item_id, payload)

      process_response("Hubspot Line Item", "update", hs_line_item)

      Rails.logger.info "[INFO] [SYNC.NETSUITE_TO_HUBSPOT.ITEM] [UPDATE] [item_id: #{item[:itemId]}, line_item_id: #{hs_line_item[:id]}] Hubspot line item updated"
      Rails.logger.info "[INFO] [SYNC.NETSUITE_TO_HUBSPOT.ITEM] [COMPLETE] [item_id: #{item[:itemId]}, line_item_id: #{hs_line_item[:id]}] Netsuite item synchronized successfully"
    end

    private
      def line_item_payload(item)
        {
          "properties": {
            "name": item[:itemName],
            "quantity": item[:quantity],
            "price": item[:amount],
            "description": item[:description],
            "netsuite_item_id": item[:itemId]
          }
        }
      end

      # Remove Association betweeen HubSpot objects and line items that are not present in the corresponding
      # NetSuite record (for example, a sales order or estimate).
      #
      # - hs_line_item_ids: array of HubSpot line item IDs associated with the object
      # - from_object_id/from_object_type: HubSpot object used in the association
      def remove_line_items(hs_line_item_ids, from_object_id, from_object_type, ns_item_ids)
        hs_line_item_ids.each do |hs_item_id|
          hs_line_item = Hubspot::LineItem.find_by_id(hs_item_id)

          next unless hs_line_item.present?
          next if ns_item_ids.include?(hs_line_item[:netsuite_item_id])

          remove_line_item_association(hs_item_id, from_object_id, from_object_type)
        end
      end

      # Return an array of HubSpot line item IDs associated with the given object.
      def line_item_ids_for_associated_object(object_id, object_type)
        line_items = Hubspot::LineItem.find_by_object_id(object_id, object_type)

        return [] unless line_items.present? && line_items.is_a?(Array)

        line_items.map { |item| item["toObjectId"].to_s }
      end

      # Remove the association between a HubSpot line item and a HubSpot object.
      # Raises if the remove operation does not return success.
      def remove_line_item_association(hs_item_id, from_object_id, from_object_type)
        response = Hubspot::LineItem.remove_line_item_association(hs_item_id, from_object_id, from_object_type)

        unless response == "success"
          raise "Failed to remove association of line item with ID #{hs_item_id} to #{from_object_type} with ID #{from_object_id}"
        end

        Rails.logger.info "[INFO] [API.HUBSPOT.ASSOCIATION] [DELETE] [line_item_id: #{hs_item_id}, #{from_object_type}_id: #{from_object_id}] Line item association removed successfully"
      end

      # Associate a HubSpot line item to a HubSpot object using the provided
      # association payload builder.
      def associate_line_item(line_item_id, object_id, object_type, association_type)
        payload = payload_to_associate(line_item_id, object_id, association_type)
        results = Hubspot::LineItem.associate_line_item(payload, object_type)

        unless results.present?
          raise "Failed to associate line item with ID #{line_item_id} to #{object_type} with ID #{object_id}"
        end

        Rails.logger.info "[INFO] [API.HUBSPOT.ASSOCIATION] [CREATE] [line_item_id: #{line_item_id}, #{object_type}_id: #{object_id}] Line item associated successfully"
      end

      def line_item_search_filters(item, existing_ids)
        [
          build_search_filter("netsuite_item_id", "EQ", item[:itemId]),
          build_search_filter("hs_object_id", "IN", existing_ids, multiple: true)
        ]
      end

      def log_sync_start(item)
        Rails.logger.info "[INFO] [SYNC.NETSUITE_TO_HUBSPOT.ITEM] [START] [item_id: #{item[:itemId]}] Initiating netsuite item synchronization"
      end
  end
end
