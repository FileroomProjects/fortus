module Hubspot::Deal::NetsuiteQuoteDealHelper
  extend ActiveSupport::Concern

  included do
    def prepare_payload_for_netsuite_quote_deal(ns_quote_id)
      {
        "properties": {
          "dealname": fetch_prop_field(:dealname),
          "pipeline": "1223722438",
          "dealstage": "1979552198",
          "netsuite_quote_id": ns_quote_id,
          "amount": fetch_prop_field(:amount),
          "netsuite_location": "https://4800298-sb1.suitetalk.api.netsuite.com/services/rest/record/v1/estimate/4431402",
          "netsuite_origin": "netsuite"
        }
      }
    end

    def prepare_payload_for_deal_to_contact_association(hs_deal_id, hs_contact_id)
      {
        "inputs": [
          {
            "from": {  "id": hs_deal_id },
            "to": { "id": hs_contact_id },
            "type": "deal_to_contact"
          }
        ]
      }
    end

    def prepare_payload_for_deal_to_company_association(hs_deal_id, hs_company_id)
      {
        "inputs": [
          {
            "from": { "id": hs_deal_id },
            "to": { "id": hs_company_id },
            "type": "deal_to_company"
          }
        ]
      }
    end

    def prepare_payload_for_deal_to_deal_association(child_deal_id, parent_deal_id)
      {
        "inputs": [
          {
            "from": { "id": child_deal_id },
            "to": { "id": parent_deal_id },
            "type": "deal_to_deal"
          }
        ]
      }
    end

    def prepare_payload_for_line_item_to_deal_association(line_item_id, deal_id)
      {
        "inputs": [
          {
            "from": { "id": line_item_id },
            "to": { "id": deal_id },
            "type": "line_item_to_deal"
          }
        ]
      }
    end

    def line_item_payload
      {
        "properties": {
          "name": "Product ABC",
          "quantity": "1",
          "price": "500"
        }
      }
    end
  end
end
