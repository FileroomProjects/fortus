module Netsuite::SalesOrder::Hubspot::DealHelper
  extend ActiveSupport::Concern

  included do
    def fetch_hubspot_parent_deal
      hs_parent_deal = Hubspot::Deal.search(payload_for_search_hubspot_parent_deal)
      if hs_parent_deal.present? && hs_parent_deal[:id].present?
        Rails.logger.info "************** Hubspot parent deal found ID #{hs_parent_deal[:id]}"
        hs_parent_deal
      else
        raise "Hubspot Parent deal not found"
      end
    end

    def payload_for_search_hubspot_parent_deal
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
                operator: "NEQ",
                value: "1223722438"
              }
            ]
          }
        ]
      }
    end

    def fetch_hubspot_child_deal
      hs_deal = Hubspot::Deal.search(payload_for_search_hubspot_child_deal)
      if hs_deal.present? && hs_deal[:id].present?
        Rails.logger.info "************** Hubspot child deal found with ID #{hs_deal[:id]}"
        hs_deal
      else
        raise "Hubspot Child deal not found"
      end
    end

    def payload_for_search_hubspot_child_deal
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
                operator: "EQ",
                value: "1223722438"
              }
            ]
          }
        ]
      }
    end

    def update_hubspot_parent_deal
      body = payload_for_update_parent_deal
      @client = Hubspot::Client.new(body: body)

      if deal = @client.update_deal
        deal = deal.with_indifferent_access
      end
      deal
    end

    def update_hubspot_child_deal
      body = payload_for_update_child_deal
      @client = Hubspot::Client.new(body: body)

      if deal = @client.update_deal
        deal = deal.with_indifferent_access
      end
      deal
    end

    def payload_for_update_parent_deal
      {
        deal_id: @hs_parent_deal[:id],
        "dealstage": "closedwon"
      }
    end

    def payload_for_update_child_deal
      {
        deal_id: @hs_child_deal[:id],
        "dealstage": "closedwon"
      }
    end
  end
end
