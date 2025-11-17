module Hubspot::Deal::NetsuiteQuoteHelper
  extend ActiveSupport::Concern

  included do
    def prepare_payload_for_netsuite_quote
      hs_contact_details = associated_contact_details
      hs_company_details = associated_company_details
      {
        "entity": { "id": hs_company_details[:netsuite_company_id]&.fetch("value", "") },
        "custbody_so_title": fetch_prop_field(:dealname),
        "location": { "id": "80" },
        "custbody34": Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "custbody20": { refName: "Opportunity " }, # Origin
        "opportunity": { "id": @netsuite_opportunity_id }, # Delivery Contact Number
        "custbody37": { "id": "6" }, # Case Type
        "custbody1": { "id": hs_contact_details[:netsuite_contact_id]&.fetch("value", "") }, # contact
        "custbody_phone_number": hs_contact_details[:phone]&.fetch("value", "") || "4843211147",
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
