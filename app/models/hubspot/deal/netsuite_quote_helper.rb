module Hubspot::Deal::NetsuiteQuoteHelper
  extend ActiveSupport::Concern

  included do
    NETSUITE_LOCATION_ID = "80"
    NETSUITE_CASE_TYPE_ID = "6"
    NETSUITE_ORIGIN_REF_NAME  = "Opportunity "

    def find_or_create_netsuit_quote
      netsuite_quote_id = fetch_prop_field(:netsuite_quote_id)
      if netsuite_quote_id.blank?
        ns_quote = create_netsuite_quote_estimate_and_update_hubspot_deal
        return ns_quote
      end

      ns_quote = Netsuite::Quote.show(netsuite_quote_id)
      if ns_quote.present?
        Rails.logger.info "************** Netsuite estimate already exists with ID #{ns_quote[:id]}"
        ns_quote
      else
        create_netsuite_quote_estimate_and_update_hubspot_deal
      end
    end

    def create_netsuite_quote_estimate_and_update_hubspot_deal
      Rails.logger.info "************** Creating Netsuite estimate"

      payload = prepare_payload_for_netsuite_quote
      ns_quote = Netsuite::Quote.create(payload)

      unless object_present_with_id?(ns_quote)
        raise "Failed to create Netsuite estimate"
      end

      Rails.logger.info "************** Created Netsuite Quote estimate with ID #{ns_quote[:id]}"
      Rails.logger.info "************** Updating Hubspot deal with netsuite_quote_id #{ns_quote[:id]}"

      update({ "netsuite_quote_id": ns_quote[:id] })
      ns_quote
    end

    private
      def prepare_payload_for_netsuite_quote
        hs_contact_details = associated_contact_details
        ns_company_id = associated_company_details[:netsuite_company_id]&.fetch("value", "")
        ns_contact_id = hs_contact_details[:netsuite_contact_id]&.fetch("value", "")
        raise "netsuite_company_id is not present in hubspot company details" if ns_company_id.blank?
        raise "netsuite_contact_id is not present in hubspot contact details" if ns_contact_id.blank?
        {
          "entity": { "id": ns_company_id }, # Customer
          "custbody_so_title": fetch_prop_field(:dealname), # Title
          "location": { "id": NETSUITE_LOCATION_ID },
          "custbody34": Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"), # Incident Date/ Time
          "custbody20": { refName: NETSUITE_ORIGIN_REF_NAME }, # Origin
          "opportunity": { "id": @netsuite_opportunity_id },
          "custbody37": { "id": NETSUITE_CASE_TYPE_ID }, # Case Type
          "custbody1": { "id": ns_contact_id }, # Contact
          "custbody_phone_number": hs_value(hs_contact_details, :phone, "0000000000"), # Delivery Contact Number
          "item": {
            "items": [
              {
                "item": { "id": "2266" },
                "quantity": 1,
                "rate": 500
              }
            ]
          }
        }
      end
  end
end
