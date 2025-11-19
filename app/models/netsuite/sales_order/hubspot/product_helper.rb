module Netsuite::SalesOrder::Hubspot::ProductHelper
  extend ActiveSupport::Concern

  included do
    def create_product_and_line_items_in_hubspot_order(hs_order)
      args[:items].each do |item|
        hs_line_item = Hubspot::LineItem.create(line_item_payload(item))
        if hs_line_item.present? && hs_line_item[:id].present?
          Rails.logger.info "************** Created Hubspot Line Item with ID #{hs_line_item[:id]}"
          associate_line_item_with_order(hs_line_item, hs_order)
        else
          raise "Failed to create Hubspot Line Item for item ID #{item[:id]}"
        end
        # hs_product = Hubspot::Product.search(payload_for_search_hubspot_product(item))
        # if hs_product.present? && hs_product[:id].present?
        #   associate_line_item_with_product(hs_line_item, hs_product)
        #   Rails.logger.info "************** Hubspot Product already exists with ID #{hs_product[:id]}"
        # else
        #   hs_product = Hubspot::Product.create(product_payload(item))
        #   if hs_product.present? && hs_product[:id].present?
        #     associate_line_item_with_product(hs_line_item, hs_product)
        #     Rails.logger.info "************** Created Hubspot Product with ID #{hs_product[:id]}"
        #   else
        #     raise "Failed to create Hubspot Product for item ID #{item[:id]}"
        #   end
        # end
      end
    end

    def associate_line_item_with_product(hs_line_item, hs_product)
      body = payload_to_associate_line_item_with_product(hs_line_item, hs_product)
      @client = Hubspot::Client.new(body: body)
      @client.create_association("line_items", "products")
    end

    def associate_line_item_with_order(hs_line_item, hs_order)
      body = payload_to_associate_line_item_with_order(hs_line_item, hs_order)
      @client = Hubspot::Client.new(body: body)
      @client.create_association("line_items", "orders")
    end

    def payload_for_search_hubspot_product(item)
      {
        filterGroups: [
          {
            filters: [
              {
                propertyName: "hs_sku",
                operator: "EQ",
                value: item[:id]
              }
            ]
          }
        ]
      }
    end

    def line_item_payload(item)
      {
        "properties": {
          # "name": "name_#{item[:id]}",
          "quantity": item[:quantity],
          "price": item[:rate],
          "description": item[:description]
        }
      }
    end

    def product_payload(item)
      {
        "properties": {
          # "name": "name_#{item[:id]}",
          "hs_sku": "#{item[:id]}",
          "price": item[:rate],
          "description": item[:description]
        }
      }
    end

    def payload_to_associate_line_item_with_product(hs_line_item, hs_product)
      {
        "inputs": [
          {
            "from": { "id": hs_line_item[:id] },
            "to": { "id": hs_product[:id] },
            "type": "line_item_to_product"
          }
        ]
      }
    end

    def payload_to_associate_line_item_with_order(hs_line_item, hs_order)
      {
        "inputs": [
          {
            "from": { "id": hs_line_item[:id] },
            "to": { "id": hs_order[:id] },
            "type": "line_item_to_order"
          }
        ]
      }
    end
  end
end
