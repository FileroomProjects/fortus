module Hubspot
  class Deal < Hubspot::Base
    include Hubspot::Deal::NetsuiteOpportunityHelper
    include Hubspot::Deal::NetsuiteContactHelper
    include Hubspot::Deal::NetsuiteCompanyHelper
    include Hubspot::Deal::NetsuiteQuoteHelper
    
    def update(attributes={})
      attributes = attributes.merge({deal_id: self.args[:objectId]})
      @client = Hubspot::Client.new(body: attributes)

      @client.update_deal
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
      contact_id = Hubspot::Contact.find_by_deal_id(args[:objectId])[:toObjectId]
      raise "Contact is not present" if contact_id.blank?

      Hubspot::Contact.find_by_id(contact_id)
    end

    def associated_company_details
      company_id = Hubspot::Company.find_by_deal_id(args[:objectId])[:toObjectId]
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
        @opportunity_payload = prepare_payload_for_netsuite_opportunity
        ns_opportunity = Netsuite::Opportunity.create(@opportunity_payload)
        if ns_opportunity && ns_opportunity[:id].present?
          @netsuite_opportunity_id = ns_opportunity[:id]
          update({
            "netsuite_opportunity_id": ns_opportunity[:id]
          })
        end
      end

      if @netsuite_opportunity_id.present?
        @ns_quote_payload = prepare_payload_for_netsuite_quote
        ns_quote = Netsuite::Quote.create(@ns_quote_payload)
      end
    end

    def fetch_prop_field(field_name)
      f_value = (properties[field_name.to_sym] || properties[field_name.to_s])[:versions]&.first
      f_value[:value] if f_value.present?
    end
  end
end
