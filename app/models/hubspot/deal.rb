module Hubspot
  class Deal < Hubspot::Base
    include Hubspot::Deal::NetsuiteOpportunityHelper
    include Hubspot::Deal::NetsuiteContactHelper
    include Hubspot::Deal::NetsuiteCompanyHelper
    include Hubspot::Deal::NetsuiteQuoteHelper
    include Hubspot::Deal::HubspotQuoteDealHelper

    def update(attributes = {})
      attributes = attributes.merge({ deal_id: deal_id })
      Hubspot::Client.new(body: attributes).update_deal
    end

    def self.search(args = {})
      client = Hubspot::Client.new(body: args)

      deal = client.search_object("deals")
      deal&.with_indifferent_access
    end

    def associated_company
      Hubspot::Company.fetch_by_deal_id(deal_id)
    end

    def associated_contact
      Hubspot::Contact.find_by_deal_id(deal_id)
    end

    def associated_campaign
      Hubspot::Campaign.find_by_deal_id(deal_id)
    end

    def associated_contact_details
      contact_id = Hubspot::Contact.find_by_deal_id(deal_id)&.[](:toObjectId)
      raise "Contact is not present" if contact_id.blank?

      Hubspot::Contact.find_by_id(contact_id)
    end

    def associated_company_details
      company_id = Hubspot::Company.find_by_deal_id(deal_id)&.[](:toObjectId)
      raise "Company is not present" if company_id.blank?

      Hubspot::Company.find_by_id(company_id)
    end

    def self.find_by(args)
      client = Hubspot::Client.new(body: args)

      client.fetch_deal
    end

    def sync_contact_customer_with_netsuite
      handle_company_and_update_hubspot

      handle_contact_and_update_hubspot
    end

    def sync_quotes_and_opportunity_with_netsuite
      ensure_netsuite_opportunity

      create_netsuite_quote_estimate_and_create_hubspot_quote_deal if @netsuite_opportunity_id.present?
    end

    def create_netsuite_quote_estimate_and_create_hubspot_quote_deal
      Rails.logger.info "************** Creating Netsuite Quote"
      ns_quote = Netsuite::Quote.create(prepare_payload_for_netsuite_quote)

      if ns_quote[:id].present?
        Rails.logger.info "************** Created Netsuite Quote estimate with ID #{ns_quote[:id]}"
        create_and_update_hubspot_quote_deal(ns_quote)
      end
    end

    def fetch_prop_field(field_name)
      prop = properties[field_name.to_sym] || properties[field_name.to_s]
      return unless prop

      version = prop[:versions]&.first || prop["versions"]&.first
      version[:value] || version["value"]
    end

    def hs_value(hs_hash, key, value)
      hs_hash[key]&.fetch("value", "") || value
    end
  end
end
