module Netsuite::Quote::Hubspot::DealHelper
  extend ActiveSupport::Concern

  include Netsuite::Hubspot::DealHelper

  included do
    def update_hubspot_quote_deal
      hs_deal = find_deal(filters)
      payload = payload_to_update_deal(hs_deal)
      update_deal(payload)
    end

    private
      def filters
        [
          {
            propertyName: "netsuite_quote_id",
            operator: "EQ",
            value: args[:estimate][:id]
          }
        ]
      end

      def payload_to_update_deal(hs_deal)
        {
          deal_id: hs_deal[:id],
          "amount": args[:estimate][:total],
          # "terms": args[:estimate][:terms],
          # "contact_display": args[:estimate][:custbody_phone_number],
          "status": args[:estimate][:entityStatus]
        }
      end
  end
end
