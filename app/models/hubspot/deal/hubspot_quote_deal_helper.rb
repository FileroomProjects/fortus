module Hubspot::Deal::HubspotQuoteDealHelper
  extend ActiveSupport::Concern

  included do
    def find_or_create_hubspot_child_deal(ns_quote)
      hs_deal = find_quote_deal(ns_quote[:id])

      return if hs_deal&.dig(:id).present?

      hs_quote_deal = create_hubspot_quote_deal(ns_quote)
      association_for_deal(hs_quote_deal[:id], deal_id)
    end

    def create_hubspot_quote_deal(ns_quote)
      create_quote_deal_with(:regular, ns_quote)
    end

    def create_duplicate_hubspot_quote_deal(ns_quote)
      create_quote_deal_with(:duplicate, ns_quote)
    end

    def find_parent_deal
      filters = deal_filters("NEQ")
      payload = build_search_payload(filters)
      hs_deal = Hubspot::Deal.search(payload)

      raise "Hubspot parent deal not found" unless object_present_with_id?(hs_deal)

      Rails.logger.info "************** Hubspot parent deal found ID #{hs_deal[:id]}"
      hs_deal
    end

    def line_item_payload
      {
        "properties": {
          "name": "Product ABC",
          "quantity": "1",
          "price": "500",
          "netsuite_item_id": "2266"
        }
      }
    end

    def association_for_deal(hs_quote_deal_id, parent_deal_id)
      Rails.logger.info "************** Associating Quote Deal with Company, Contact, Parent Deal and Line Item"
      hs_quote_deal = Hubspot::QuoteDeal.new(hs_quote_deal_id, parent_deal_id)
      hs_quote_deal.associate_company
      hs_quote_deal.associate_contact
      hs_quote_deal.associate_parent_deal
      hs_quote_deal.associate_line_item
    end

    private
      def find_quote_deal(ns_quote_id)
        filters = deal_filters("EQ")
        payload = build_search_payload(filters)
        hs_deal = Hubspot::Deal.search(payload)

        return nil unless hs_deal&.dig(:id).present?

        Rails.logger.info "************** Hubspot quote deal found ID #{hs_deal[:id]}"
        hs_deal
      end

      def create_quote_deal_with(type, ns_quote)
        payload = quote_deal_payload(type, ns_quote[:id])
        hs_quote_deal = Hubspot::QuoteDeal.create(payload)

        return unless hs_quote_deal&.dig(:id).present?

        Rails.logger.info "************** Created Hubspot Quote Deal with ID #{hs_quote_deal[:id]}"
        hs_quote_deal
      end

      def quote_deal_payload(type, ns_quote_id)
        dealname = build_dealname(type, ns_quote_id)

        {
          "properties": {
            "dealname": dealname,
            "pipeline": ENV["HUBSPOT_DEFAULT_PIPELINE"],
            "dealstage": ENV["HUBSPOT_DEFAULT_DEALSTAGE"],
            "netsuite_quote_id": ns_quote_id,
            "amount": fetch_prop_field(:amount),
            "netsuite_location": netsuite_estimate_location(ns_quote_id),
            "netsuite_origin": "netsuite",
            "netsuite_opportunity_id": @netsuite_opportunity_id,
            "is_child": "true"
          }
        }
      end

      def deal_filters(operator)
        [
          build_search_filter("netsuite_opportunity_id", "EQ", @netsuite_opportunity_id),
          build_search_filter("pipeline", operator, ENV["HUBSPOT_DEFAULT_PIPELINE"])
        ]
      end

      def netsuite_estimate_location(ns_quote_id)
        "https://#{ENV['NETSUITE_ACCOUNT_ID']}.app.netsuite.com/app/accounting/transactions/estimate.nl?id=#{ns_quote_id}&whence="
      end

      def build_dealname(type, ns_quote_id)
        base_dealname = fetch_prop_field(:dealname)

        case type
        when :regular
          "#{ns_quote_id} #{base_dealname}"
        when :duplicate
          suffix = base_dealname.split(" ", 2)[1]
          "#{ns_quote_id} #{suffix}"
        end
      end
  end
end
