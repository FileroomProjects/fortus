module Hubspot
  class Deal < Hubspot::Base
    include Hubspot::Deal::NetsuiteOpportunityHelper
    include Hubspot::Deal::NetsuiteContactHelper
    include Hubspot::Deal::NetsuiteCompanyHelper
    include Hubspot::Deal::NetsuiteQuoteHelper
    include Hubspot::Deal::HubspotQuoteDealHelper

    def update(attributes = {})
      attributes = attributes.merge({ deal_id: self.args[:objectId] })
      @client = Hubspot::Client.new(body: attributes)

      @client.update_deal
    end

    def self.search(args = {})
      @client = Hubspot::Client.new(body: args)

      if deal = @client.search_object("deals")
        deal = deal.with_indifferent_access
      end
      deal
    end

    def associated_company
      Hubspot::Company.fetch_by_deal_id(args[:objectId])
    end

    def associated_contact
      Hubspot::Contact.find_by_deal_id(args[:objectId])
    end

    def associated_campaign
      Hubspot::Campaign.find_by_deal_id(args[:objectId])
    end

    def associated_contact_details
      contact_id = Hubspot::Contact.find_by_deal_id(args[:objectId])&.[](:toObjectId)
      raise "Contact is not present" if contact_id.blank?

      Hubspot::Contact.find_by_id(contact_id)
    end

    def associated_company_details
      company_id = Hubspot::Company.find_by_deal_id(args[:objectId])&.[](:toObjectId)
      raise "Company is not present" if company_id.blank?

      Hubspot::Company.find_by_id(company_id)
    end

    def self.find_by(args)
      @client = Hubspot::Client.new(body: args)

      @client.fetch_deal
    end

    def sync_contact_customer_with_netsuite
      handle_company_and_update_hubspot

      handle_contact_and_update_hubspot
    end

    def sync_quotes_and_opportunity_with_netsuite
      if @netsuite_opportunity_id.blank?
        create_netsuite_opportunity_and_update_hubspot_deal
      else
        @netsuite_opportunity = Netsuite::Opportunity.show(@netsuite_opportunity_id)
        if @netsuite_opportunity.present? && @netsuite_opportunity[:entityStatus]&.[](:refName) == "Open"
          Rails.logger.info "************** Netsuite Opportunity already exists with ID #{@netsuite_opportunity_id}"
        else
          create_netsuite_opportunity_and_update_hubspot_deal
        end
      end

      if @netsuite_opportunity_id.present?
        create_netsuite_quote_estimate_and_create_hubspot_quote_deal
      end
    end

    def create_netsuite_opportunity_and_update_hubspot_deal
      Rails.logger.info "************** Creating Netsuite Opportunity"
      opportunity_payload = prepare_payload_for_netsuite_opportunity
      ns_opportunity = Netsuite::Opportunity.create(opportunity_payload)
      if ns_opportunity && ns_opportunity[:id].present?
        Rails.logger.info "************** Created Netsuite Opportunity with ID #{ns_opportunity[:id]}"
        @netsuite_opportunity_id = ns_opportunity[:id]
        Rails.logger.info "************** Updating Hubspot deal with netsuite_opportunity_id #{ns_opportunity[:id]}"
        update({
          "netsuite_opportunity_id": ns_opportunity[:id]
        })
      else
        raise "Failed to create netsuite opportunity"
      end
    end

    def create_netsuite_quote_estimate_and_create_hubspot_quote_deal
      Rails.logger.info "************** Creating Netsuite Quote"
      ns_quote_payload = prepare_payload_for_netsuite_quote
      ns_quote = Netsuite::Quote.create(ns_quote_payload)
      if ns_quote && ns_quote[:id].present?
        Rails.logger.info "************** Created Netsuite Quote estimate with ID #{ns_quote[:id]}"
        create_and_update_hubspot_quote_deal(ns_quote)
      end
    end

    def fetch_prop_field(field_name)
      prop = properties[field_name.to_sym] || properties[field_name.to_s]
      return nil if prop.nil?

      version = prop[:versions]&.first || prop["versions"]&.first
      version[:value] || version["value"]
    end
  end
end
