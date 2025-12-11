module Hubspot
  class ChildDeal < Hubspot::Base
    # This model handles child deal operations in HubSpot
    # A deal in hubspot with Netsuite Quote Pipeline
    # attr_accessor :hs_deal_id, :hs_parent_deal_id, :ns_estimate_id

    # Initialize a HubSpot ChildDeal model.
    # - hs_deal_id: HubSpot child deal id
    # - hs_parent_deal_id: HubSpot parent deal id
    # - ns_estimate_id: NetSuite estimate id used to sync line items
    # def initialize(hs_deal_id, hs_parent_deal_id, ns_estimate_id)
    #   @hs_deal_id = hs_deal_id
    #   @hs_parent_deal_id = hs_parent_deal_id
    #   @ns_estimate_id = ns_estimate_id
    # end

    # # Associate the HubSpot child deal with the company from the parent deal.
    # def associate_company
    #   hs_company_id = Hubspot::Company.find_by_deal_id(hs_parent_deal_id)[:toObjectId]
    #   body = payload_to_associate(hs_deal_id, hs_company_id, "deal_to_company")
    #   create_association(body, "deals", "companies")
    # end

    # # Associate the HubSpot child deal with the contact from the parent deal.
    # def associate_contact
    #   hs_contact_id = Hubspot::Contact.find_by_deal_id(hs_parent_deal_id)[:toObjectId]
    #   body = payload_to_associate(hs_deal_id, hs_contact_id, "deal_to_contact")
    #   create_association(body, "deals", "contacts")
    # end

    # # Associate the HubSpot child deal to its parent deal.
    # def associate_parent_deal
    #   body = payload_to_associate(hs_deal_id, hs_parent_deal_id, "deal_to_deal")
    #   create_association(body, "deals", "deals")
    # end

    # # Create and associate HubSpot line items for each NetSuite estimate item.
    # def associate_line_items
    #   ns_estimate_items = Netsuite::Estimate.fetch_items(ns_estimate_id)
    #   ns_estimate_items[:items].each do |item|
    #     create_and_associate_line_item(item, hs_deal_id, "deals", "line_item_to_deal")
    #   end
    # end

    # # Send an association payload to the HubSpot client.
    # def create_association(body, from, to)
    #   client = Hubspot::Client.new(body: body)
    #   client.create_association(from, to)
    # end
  end
end
