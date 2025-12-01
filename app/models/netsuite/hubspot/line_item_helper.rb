module Netsuite::Hubspot::LineItemHelper
  extend ActiveSupport::Concern

  included do
    def sync_line_items(hs_object, object_type, association_type)
      existing_ids = line_item_ids_for_associated_object(hs_object[:id], object_type)

      raise "Missing args or args[:items]" if args.nil? || args[:items].nil?

      if existing_ids.blank?
        args[:items].each do |item|
          create_line_item(item, hs_object[:id], object_type, association_type)
        end
        return
      end

      args[:items].each do |item|
        create_or_update_line_item(item, existing_ids, hs_object[:id], object_type, association_type)
      end

      updated_ids = line_item_ids_for_associated_object(hs_object[:id], object_type)
      ns_item_ids = args[:items].map { |item| item[:itemId] }

      remove_line_items(updated_ids, hs_object[:id], object_type, ns_item_ids)
    end

    private
      def create_or_update_line_item(item, existing_ids, object_id, object_type, association_type)
        hs_line_item = find_line_item(item, existing_ids)

        if object_present_with_id?(hs_line_item)
          update_line_item(hs_line_item[:id], item)
        else
          create_line_item(item, object_id, object_type, association_type)
        end
      end

      def create_line_item(item, object_id, object_type, association_type)
        payload = line_item_payload(item)
        hs_line_item = Hubspot::LineItem.create(payload)

        unless object_present_with_id?(hs_line_item)
          raise "Failed to create Hubspot Line Item for item ID #{item[:id]}"
        end

        Rails.logger.info "************** Create Hubspot Line Item with ID #{hs_line_item[:id]}"
        associate_line_item(hs_line_item[:id], object_id, object_type, association_type)
      end

      def find_line_item(item, existing_ids)
        filters = [
          build_search_filter("netsuite_item_id", "EQ", item[:itemId]),
          build_search_filter("hs_object_id", "IN", existing_ids, multiple: true)
        ]

        payload = build_search_payload(filters)
        hs_line_item = Hubspot::LineItem.search(payload)

        return unless object_present_with_id?(hs_line_item)

        Rails.logger.info "************** Found Hubspot Line Item with ID #{hs_line_item[:id]}"
        hs_line_item
      end

      def update_line_item(line_item_id, item)
        payload = line_item_payload(item)
        hs_line_item = Hubspot::LineItem.update(line_item_id, payload)

        Rails.logger.info "************** Update Hubspot Line Item with ID #{hs_line_item[:id]}" if object_present_with_id?(hs_line_item)
      end

      def line_item_payload(item)
        {
          "properties": {
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
        Rails.logger.info "************** Removing Line Item with ID #{hs_item_id} from #{from_object_type}: #{from_object_id}"

        response = Hubspot::LineItem.remove_line_item_association(hs_item_id, from_object_id, from_object_type)

        Rails.logger.info "************* Removed Line Item with ID #{hs_item_id}" if response == "success"
      end

      def associate_line_item(line_item_id, object_id, object_type, association_type)
        payload = payload_to_associate(line_item_id, object_id, association_type)
        Hubspot::LineItem.associate_line_item(payload, object_type)
      end
  end
end
