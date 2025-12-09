module HubspotLineItem
  extend ActiveSupport::Concern

  included do
    def sync_line_items(hs_object, object_type, association_type)
      existing_ids = line_item_ids_for_associated_object(hs_object[:id], object_type)

      raise "Missing args or args[:items]" if args.nil? || args[:items].nil?

      if existing_ids.blank?
        args[:items].each do |item|
          Rails.logger.info "[INFO] [SYNC.NETSUITE_TO_HUBSPOT.ITEM] [START] [item_id: #{item[:itemId]}] Initiating netsuite item synchronization"
          create_and_associate_line_item(item, hs_object[:id], object_type, association_type)
        end
        return
      end

      args[:items].each do |item|
        Rails.logger.info "[INFO] [SYNC.NETSUITE_TO_HUBSPOT.ITEM] [START] [item_id: #{item[:itemId]}] Initiating netsuite item synchronization"
        create_or_update_line_item(item, existing_ids, hs_object[:id], object_type, association_type)
      end

      updated_ids = line_item_ids_for_associated_object(hs_object[:id], object_type)
      ns_item_ids = args[:items].map { |item| item[:itemId] }

      remove_line_items(updated_ids, hs_object[:id], object_type, ns_item_ids)
    end

    def create_or_update_line_item(item, existing_ids, object_id, object_type, association_type)
      filters = line_item_search_filters(item, existing_ids)
      hs_line_item = find_line_item(filters)

      if object_present_with_id?(hs_line_item)
        update_line_item(hs_line_item[:id], item)
      else
        create_and_associate_line_item(item, object_id, object_type, association_type)
      end
    end

    def create_and_associate_line_item(item, object_id, object_type, association_type)
      payload = line_item_payload(item)
      hs_line_item = Hubspot::LineItem.create(payload)
      process_response("Hubspot Line Item", "create", hs_line_item)
      Rails.logger.info "[INFO] [SYNC.NETSUITE_TO_HUBSPOT.ITEM] [CREATE] [item_id: #{item[:itemId]}, line_item_id: #{hs_line_item[:id]}] Hubspot line item created"
      Rails.logger.info "[INFO] [SYNC.NETSUITE_TO_HUBSPOT.ITEM] [COMPLETE] [item_id: #{item[:itemId]}, line_item_id: #{hs_line_item[:id]}] Netsuite item synchronized successfully"
      associate_line_item(hs_line_item[:id], object_id, object_type, association_type)
    end

    def find_line_item(filters)
      payload = build_search_payload(filters)
      hs_line_item = Hubspot::LineItem.search(payload)
      if object_present_with_id?(hs_line_item)
        Rails.logger.info "[INFO] [API.HUBSPOT.LINE_ITEM] [SEARCH] [line_item_id: #{hs_line_item[:id]}] HubSpot line item found"
        hs_line_item
      else
        Rails.logger.info "[INFO] [API.HUBSPOT.LINE_ITEM] [SEARCH] [filters: #{filters}] HubSpot line item not found"
      end
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

      def remove_line_items(hs_line_item_ids, from_object_id, from_object_type, ns_item_ids)
        hs_line_item_ids.each do |hs_item_id|
          hs_line_item = Hubspot::LineItem.find_by_id(hs_item_id)

          next unless hs_line_item.present?
          next if ns_item_ids.include?(hs_line_item[:netsuite_item_id])

          remove_line_item_association(hs_item_id, from_object_id, from_object_type)
        end
      end

      def line_item_ids_for_associated_object(object_id, object_type)
        line_items = Hubspot::LineItem.find_by_object_id(object_id, object_type)

        return [] unless line_items.present? && line_items.is_a?(Array)

        line_items.map { |item| item["toObjectId"].to_s }
      end

      def remove_line_item_association(hs_item_id, from_object_id, from_object_type)
        response = Hubspot::LineItem.remove_line_item_association(hs_item_id, from_object_id, from_object_type)

        raise "Failed to remove line item with ID #{hs_item_id}" unless response == "success"
      end

      def associate_line_item(line_item_id, object_id, object_type, association_type)
        payload = payload_to_associate(line_item_id, object_id, association_type)
        Hubspot::LineItem.associate_line_item(payload, object_type)
      end

      def line_item_search_filters(item, existing_ids)
        [
          build_search_filter("netsuite_item_id", "EQ", item[:itemId]),
          build_search_filter("hs_object_id", "IN", existing_ids, multiple: true)
        ]
      end
  end
end
