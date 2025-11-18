module Netsuite
  class SalesOrder < Netsuite::Base
    def sync_sales_order_with_hubspot
      @payload = prepare_payload_for_hubspot_sales_order
      byebug
    end

    def prepare_payload_for_hubspot_sales_order
      {
        inputs: [
          {
            properties: {
              hs_order_name: args[:sales_order][:title],
              hs_order_date: args[:sales_order][:trandate],
              amount: args[:sales_order][:total],
              hs_currency: 'AUD',
              # hs_payment_status: PENDING
            },
            associations: [
              {
                to: { id: args[:customer][:id] },
                types: [{
                  associationCategory: 'HUBSPOT_DEFINED',
                  associationTypeId: 509 #company
                }]
              },
              {
                to: { id: args[:sales_order][:contact_id] },
                types: [{
                  associationCategory: 'HUBSPOT_DEFINED',
                  associationTypeId: 507# contact
                }]
              }
            ]
          }
        ]
      }
    end
  end
end
