module Hubspot::Deal::HubspotQuoteDealHelper
  extend ActiveSupport::Concern

  included do
    def create_and_update_hubspot_quote_deal(ns_quote)
      payload = prepare_payload_for_netsuite_quote_deal(ns_quote[:id])
      hs_quote_deal = Hubspot::QuoteDeal.create(payload)

      return unless hs_quote_deal&.dig(:id).present?

      Rails.logger.info "************** Created Hubspot Quote Deal with ID #{hs_quote_deal[:id]}"
      association_for_deal(hs_quote_deal[:id])
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
      def find_quote_deal
        hs_deal = Hubspot::Deal.search(quote_deal_search_payload)

        return unless hs_deal[:id].present?

        Rails.logger.info "************** Hubspot quote deal found ID #{hs_deal[:id]}"
        hs_deal
      end

      def association_for_deal(hs_quote_deal_id)
        Rails.logger.info "************** Associating Quote Deal with Company, Contact, Parent Deal and Line Item"
        hs_quote_deal = Hubspot::QuoteDeal.new(hs_quote_deal_id, deal_id)
        hs_quote_deal.associate_company
        hs_quote_deal.associate_contact
        hs_quote_deal.associate_parent_deal
        hs_quote_deal.associate_line_item
      end

      def prepare_payload_for_netsuite_quote_deal(ns_quote_id)
        {
          "properties": {
            "dealname": fetch_prop_field(:dealname),
            "pipeline": ENV["HUBSPOT_DEFAULT_PIPELINE"], # Netsuite Quotes pipeline
            "dealstage": ENV["HUBSPOT_DEFAULT_DEALSTAGE"], # Open stage
            "netsuite_quote_id": ns_quote_id,
            "amount": fetch_prop_field(:amount),
            "netsuite_location": "#{Netsuite::Base::BASE_URL}/estimate/#{ns_quote_id}",
            "netsuite_origin": "netsuite"
          }
        }
      end
  end
end
