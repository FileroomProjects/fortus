module Hubspot
  class QuoteDeal < Hubspot::Base
    include Hubspot::Deal::HubspotQuoteDealHelper
    attr_accessor :hs_deal_id, :hs_parent_deal_id

    def initialize(hs_deal_id, hs_parent_deal_id)
      @hs_deal_id = hs_deal_id
      @hs_parent_deal_id = hs_parent_deal_id
    end

    def self.create(args = {})
      @client = Hubspot::Client.new(body: args)
      if quote_deal = @client.create_quote_deal
        quote_deal = quote_deal.with_indifferent_access
      end
      quote_deal
    end

    def associate_company
      hs_company_id = Hubspot::Company.find_by_deal_id(hs_parent_deal_id)[:toObjectId]
      body = prepare_payload_for_deal_to_company_association(hs_deal_id, hs_company_id)
      create_association(body, "deals", "companies")
    end

    def associate_contact
      hs_contact_id = Hubspot::Contact.find_by_deal_id(hs_parent_deal_id)[:toObjectId]
      body = prepare_payload_for_deal_to_contact_association(hs_deal_id, hs_contact_id)
      create_association(body, "deals", "contacts")
    end

    def associate_parent_deal
      body = prepare_payload_for_deal_to_deal_association(hs_deal_id, hs_parent_deal_id)
      create_association(body, "deals", "deals")
    end

    def associate_line_item
      line_item = Hubspot::LineItem.create(line_item_payload)
      line_item_id = line_item[:id]
      body = prepare_payload_for_line_item_to_deal_association(line_item_id, hs_deal_id)
      create_association(body, "line_items", "deals")
    end

    def create_association(body, from, to)
      @client = Hubspot::Client.new(body: body)
      @client.create_association(from, to)
    end
  end
end
