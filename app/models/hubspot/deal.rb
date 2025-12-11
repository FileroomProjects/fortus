module Hubspot
  class Deal < Hubspot::Base
    include Hubspot::Deal::BaseHelper

    # Update a HubSpot deals.
    def self.update(args = {})
      client = Hubspot::Client.new(body: args)
      deal = client.update_deal
      deal&.with_indifferent_access
    end

    # Create a HubSpot deal with the provided args.
    def self.create(args = {})
      client = Hubspot::Client.new(body: args)
      deal = client.create_objects("deals")
      deal&.with_indifferent_access
    end

    # Search HubSpot deals using provided filters and return first match.
    def self.search(args = {})
      client = Hubspot::Client.new(body: args)

      deal = client.search_object("deals")
      deal&.with_indifferent_access
    end

    # Fetch child deals associated with a parent deal.
    def self.child_deals(parent_deal_id)
      client = Hubspot::Client.new(body: { from_object_id: parent_deal_id })
      client.fetch_object_by_associated_object_id("deals", "deals")
    end

    # Return the company associated with this deal.
    def associated_company
      Hubspot::Company.find_by_deal_id(deal_id)
    end

    # Return the contact associated with this deal.
    def associated_contact
      Hubspot::Contact.find_by_deal_id(deal_id)
    end

    # Return the campaign associated with this deal (if any).
    def associated_campaign
      Hubspot::Campaign.find_by_deal_id(deal_id)
    end

    # Fetch full contact details for the contact associated with this deal.
    def associated_contact_details
      contact_id = Hubspot::Contact.find_by_deal_id(deal_id)&.[](:toObjectId)
      raise "Contact is not present" if contact_id.blank?

      contact = Hubspot::Contact.find_by_id(contact_id)
      if contact.present?
        Rails.logger.info "[INFO] [API.HUBSPOT.CONTACT] [FETCH] [company_id: #{contact_id}] HubSpot contact deatils fetched"
        contact
      else
        raise "Hubspot Contact details are blank"
      end
    end

    # Fetch full company details for the company associated with this deal.
    def associated_company_details
      company_id = Hubspot::Company.find_by_deal_id(deal_id)&.[](:toObjectId)
      raise "Company is not present" if company_id.blank?

      company = Hubspot::Company.find_by_id(company_id)
      if company.present?
        Rails.logger.info "[INFO] [API.HUBSPOT.COMPANY] [FETCH] [company_id: #{company_id}] HubSpot company deatils fetched"
        company
      else
        raise "Hubspot Company details are blank"
      end
    end

    def self.find_by(args)
      client = Hubspot::Client.new(body: args)

      deal = client.fetch_deal
      deal&.with_indifferent_access
    end

    # Sync associated company, opportunity and contact with NetSuite.
    def sync_contact_customer_with_netsuite
      handle_company_and_update_hubspot

      handle_contact_and_update_hubspot

      find_or_create_netsuite_opportunity
    end

    # Helper to fetch a property value from HubSpot property payloads (handles different shapes).
    def fetch_prop_field(field_name)
      prop = properties[field_name.to_sym] || properties[field_name.to_s]
      return unless prop

      version = prop[:versions]&.first || prop["versions"]&.first
      version[:value] || version["value"]
    end

    # Return value from a HubSpot hash key if present, otherwise fallback value.
    def hs_value(hs_hash, key, value)
      hs_hash[key]&.fetch("value", "") || value
    end
  end
end
