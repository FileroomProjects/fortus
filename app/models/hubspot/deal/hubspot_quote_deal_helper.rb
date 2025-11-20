module Hubspot::Deal::HubspotQuoteDealHelper
  extend ActiveSupport::Concern

  included do
    def prepare_payload_for_netsuite_quote_deal(ns_quote_id)
      {
        "properties": {
          "dealname": fetch_prop_field(:dealname),
          "pipeline": ENV["HUBSPOT_DEFAULT_PIPELINE"], # Netsuite Quotes pipeline
          "dealstage": ENV["HUBSPOT_DEFAULT_DEALSTAGE"], # Open stage
          "netsuite_quote_id": ns_quote_id,
          "amount": fetch_prop_field(:amount),
          "netsuite_location": "https://#{ENV['NETSUITE_ACCOUNT_ID']}.suitetalk.api.netsuite.com/services/rest/record/v1/estimate/#{ns_quote_id}",
          "netsuite_origin": "netsuite",
          "netsuite_opportunity_id": @netsuite_opportunity_id
        }
      }
    end

    def prepare_payload_for_deal_to_contact_association(hs_deal_id, hs_contact_id)
      prepare_association_payload(hs_deal_id, hs_contact_id, "deal_to_contact")
    end

    def prepare_payload_for_deal_to_company_association(hs_deal_id, hs_company_id)
      prepare_association_payload(hs_deal_id, hs_company_id, "deal_to_company")
    end

    def prepare_payload_for_deal_to_deal_association(child_deal_id, parent_deal_id)
      prepare_association_payload(child_deal_id, parent_deal_id, "deal_to_deal")
    end

    def prepare_payload_for_line_item_to_deal_association(line_item_id, deal_id)
      prepare_association_payload(line_item_id, deal_id, "line_item_to_deal")
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

    private
      def prepare_association_payload(from_id, to_id, type)
        {
          "inputs" => [
            {
              "from" => { "id" => from_id },
              "to" => { "id" => to_id },
              "type" => type
            }
          ]
        }
      end
  end
end
