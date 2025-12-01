module Hubspot::Deal::HubspotQuoteDealHelper
  extend ActiveSupport::Concern

  included do
    def find_or_create_hubspot_child_deal(ns_quote)
      hs_deal = find_quote_deal(ns_quote[:id])

      return if hs_deal&.dig(:id).present?

      create_and_update_hubspot_quote_deal(ns_quote)
    end

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
          "price": "500",
          "netsuite_item_id": "123"
        }
      }
    end

    private
      def find_quote_deal(ns_quote_id)
        filters = deal_filters(ns_quote_id)
        payload = build_search_payload(filters)
        hs_deal = Hubspot::Deal.search(payload)

        return nil unless hs_deal&.dig(:id).present?

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
            "dealname": "#{fetch_prop_field(:dealname)} child",
            "pipeline": ENV["HUBSPOT_DEFAULT_PIPELINE"],
            "dealstage": ENV["HUBSPOT_DEFAULT_DEALSTAGE"],
            "netsuite_quote_id": ns_quote_id,
            "amount": fetch_prop_field(:amount),
            "netsuite_location": netsuite_estimate_location(ns_quote_id),
            "netsuite_origin": "netsuite",
            "netsuite_opportunity_id": @netsuite_opportunity_id
          }
        }
      end

      def deal_filters(ns_quote_id)
        [
          build_search_filter("netsuite_quote_id", "EQ", ns_quote_id),
          build_search_filter("pipeline", "EQ", ENV["HUBSPOT_DEFAULT_PIPELINE"])
        ]
      end

      def netsuite_estimate_location(ns_quote_id)
        "https://#{ENV['NETSUITE_ACCOUNT_ID']}.app.netsuite.com/app/accounting/transactions/estimate.nl?id=#{ns_quote_id}&whence="
      end
  end
end
