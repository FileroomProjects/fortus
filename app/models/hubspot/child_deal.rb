module Hubspot
  class ChildDeal < Hubspot::Base
    # This model handles child deal operations in HubSpot
    # A deal in hubspot with Netsuite Quote Pipeline
    include Hubspot::Deal::HubspotChildDealHelper
    attr_accessor :hs_deal_id, :hs_parent_deal_id, :ns_estimate_id

    def initialize(hs_deal_id, hs_parent_deal_id, ns_estimate_id)
      @hs_deal_id = hs_deal_id
      @hs_parent_deal_id = hs_parent_deal_id
      @ns_estimate_id = ns_estimate_id
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

    def associate_line_items
      ns_estimate_items = Netsuite::Estimate.fetch_items(ns_estimate_id)
      ns_estimate_items[:items].each do |item|
        create_and_associate_line_item(item, hs_deal_id, "deals", "line_item_to_deal")
      end
    end

    def create_association(body, from, to)
      client = Hubspot::Client.new(body: body)
      client.create_association(from, to)
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
  end
end
