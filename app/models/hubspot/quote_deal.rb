module Hubspot
  class QuoteDeal < Hubspot::Base
    # This model handles quote deal operations in HubSpot
    # A deal in hubspot with Netsuite Quote Pipeline
    include Hubspot::Deal::HubspotQuoteDealHelper
    attr_accessor :hs_deal_id, :hs_parent_deal_id

    def initialize(hs_deal_id, hs_parent_deal_id)
      @hs_deal_id = hs_deal_id
      @hs_parent_deal_id = hs_parent_deal_id
    end

    def self.create(args = {})
      client = Hubspot::Client.new(body: args)
      quote_deal = client.create_objects("deals")
      quote_deal&.with_indifferent_access
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
      line_item = Hubspot::LineItem.create(line_item_payload)
      line_item_id = line_item[:id]
      body = payload_to_associate(line_item_id, hs_deal_id, "line_item_to_deal")
      create_association(body, "line_items", "deals")
    end

    def create_association(body, from, to)
      client = Hubspot::Client.new(body: body)
      client.create_association(from, to)
    end
  end
end
