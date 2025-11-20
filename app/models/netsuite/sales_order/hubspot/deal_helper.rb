module Netsuite::SalesOrder::Hubspot::DealHelper
  extend ActiveSupport::Concern

  included do
    def fetch_deal(operator, log_label)
      payload = build_search_payload(operator)
      hs_deal = Hubspot::Deal.search(payload)
      if hs_deal.present? && hs_deal[:id].present?
        Rails.logger.info "************** Hubspot #{log_label} deal found ID #{hs_deal[:id]}"
        hs_deal
      else
        raise "Hubspot #{log_label} deal not found"
      end
    end

    def update_parent_and_child_deal
      updated_parent_deal = update_deal(@hs_parent_deal[:id])
      if updated_parent_deal.present? && updated_parent_deal[:id].present?
        Rails.logger.info "************** Updated Hubspot Parent Deal with ID #{updated_parent_deal[:id]}"
      else
        raise "Failed to update Hubspot Parent Deal"
      end
      updated_child_deal = update_deal(@hs_child_deal[:id])
      if updated_child_deal.present? && updated_child_deal[:id].present?
        Rails.logger.info "************** Updated Hubspot Child Deal with ID #{updated_child_deal[:id]}"
      else
        raise "Failed to update Hubspot Child Deal"
      end
    end

    private
      def update_deal(deal_id)
        body = payload_for_update_deal(deal_id)
        @client = Hubspot::Client.new(body: body)

        if deal = @client.update_deal
          deal = deal.with_indifferent_access
        end
        deal
      end

      def build_search_payload(operator)
        {
          filterGroups: [
            {
              filters: [
                {
                  propertyName: "netsuite_opportunity_id",
                  operator: "EQ",
                  value: args[:opportunity][:id]
                },
                {
                  propertyName: "pipeline",
                  operator: operator,
                  value: ENV["HUBSPOT_DEFAULT_PIPELINE"]
                }
              ]
            }
          ]
        }
      end

      def payload_for_update_deal(deal_id)
        {
          deal_id: deal_id,
          "dealstage": "closedwon"
        }
      end
  end
end
