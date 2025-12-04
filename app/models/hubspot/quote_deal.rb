module Hubspot
  class QuoteDeal < Hubspot::Base
    # This model handles quote deal operations in HubSpot
    # A deal in hubspot with Netsuite Quote Pipeline
    include Hubspot::Deal::HubspotQuoteDealHelper
    attr_accessor :hs_deal_id, :hs_parent_deal_id, :ns_quote_id

    def initialize(hs_deal_id, hs_parent_deal_id, ns_quote_id)
      @hs_deal_id = hs_deal_id
      @hs_parent_deal_id = hs_parent_deal_id
      @ns_quote_id = ns_quote_id
    end

    def associate_company
      hs_company_id = Hubspot::Company.find_by_deal_id(hs_parent_deal_id)[:toObjectId]
      body = payload_to_associate(hs_deal_id, hs_company_id, "deal_to_company")
      create_association(body, "deals", "companies")
    end

    def associate_contact
      hs_contact_id = Hubspot::Contact.find_by_deal_id(hs_parent_deal_id)[:toObjectId]
      body = payload_to_associate(hs_deal_id, hs_contact_id, "deal_to_contact")
      create_association(body, "deals", "contacts")
    end

    def associate_parent_deal
      body = payload_to_associate(hs_deal_id, hs_parent_deal_id, "deal_to_deal")
      create_association(body, "deals", "deals")
    end

    def associate_line_item
      ns_quote_items = Netsuite::Quote.fetch_items(ns_quote_id)
      ns_quote_items[:items].each do |item|
        create_and_associate_line_item(item)
      end
    end

    def create_association(body, from, to)
      client = Hubspot::Client.new(body: body)
      client.create_association(from, to)
    end

    def create_and_associate_line_item(item)
      payload = line_item_payload(item)
      hs_line_item = Hubspot::LineItem.create(payload)

      unless object_present_with_id?(hs_line_item)
        raise "Failed to create Hubspot Line Item for item ID #{item[:id]}"
      end

      Rails.logger.info "************** Create Hubspot Line Item with ID #{hs_line_item[:id]}"
      associate_line_item_with_deal(hs_line_item[:id])
    end

    def line_item_payload(item)
      {
        "properties": {
          "name": item[:description],
          "quantity": item[:quantity],
          "price": item[:amount],
          "description": item[:description],
          "netsuite_item_id": item[:item][:id]
        }
      }
    end

    def associate_line_item_with_deal(line_item_id)
      payload = payload_to_associate(line_item_id, hs_deal_id, "line_item_to_deal")
      Hubspot::LineItem.associate_line_item(payload, "deals")
    end
  end
end
