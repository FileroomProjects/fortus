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
