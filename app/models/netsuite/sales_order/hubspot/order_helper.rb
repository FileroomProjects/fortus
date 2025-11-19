module Netsuite::SalesOrder::Hubspot::OrderHelper
  extend ActiveSupport::Concern

  included do
    def prepare_payload_for_hubspot_order
      {
        "properties": {
          "hs_order_name": args[:sales_order][:title],
          "hs_external_created_date": args[:sales_order][:trandate],
          "netsuite_order_number": args[:sales_order][:id],
          "hs_total_price": args[:sales_order][:total],
          "hs_currency_code": "AUD"
        },
        "associations": [
          {
            "to": {
              "id": @hs_contact[:id]
            },
            "types": [
              {
                "associationCategory": "HUBSPOT_DEFINED",
                "associationTypeId": 507 # order to contact
              }
            ]
          },
          {
            "to": {
              "id": @hs_parent_deal[:id]
            },
            "types": [
              {
                "associationCategory": "HUBSPOT_DEFINED",
                "associationTypeId": 512 # order to deal
              }
            ]
          },
          {
            "to": {
              "id": @hs_child_deal[:id]
            },
            "types": [
              {
                "associationCategory": "HUBSPOT_DEFINED",
                "associationTypeId": 512 # order to deal
              }
            ]
          },
          {
            "to": {
              "id": @hs_company[:id]
            },
            "types": [
              {
                "associationCategory": "HUBSPOT_DEFINED",
                "associationTypeId": 509 # order_to_company
              }
            ]
          }
        ]
      }
    end
  end
end
