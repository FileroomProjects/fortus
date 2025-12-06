module Hubspot::Deal::NetsuiteEstimateHelper
  extend ActiveSupport::Concern

  included do
    NETSUITE_LOCATION_ID = "80"
    NETSUITE_CASE_TYPE_ID = "6"
    NETSUITE_ORIGIN_REF_NAME  = "Opportunity "

    def prepare_payload_for_duplicate_netsuite_estimate
      ns_estimate = find_netsuite_estimate
      duplicate = ns_estimate

      %w[id tranId transactionNumber createdDate lastModifiedDate status custbody17].each do |field|
        duplicate.delete(field)
      end

      duplicate.delete_if do |k, v|
        v.is_a?(Hash) && v.key?("links") && !v.key?("id")
      end

      duplicate["item"] = Netsuite::Estimate.fetch_items(fetch_prop_field(:netsuite_quote_id))

      duplicate
    end

    def find_netsuite_estimate
      netsuite_estimate_id = fetch_prop_field(:netsuite_quote_id)

      raise "netsuite_quote_id is not present in child deal" if netsuite_estimate_id.blank?

      find_ns_estimate(netsuite_estimate_id)
    end

    def prepare_payload_for_netsuite_estimate
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
