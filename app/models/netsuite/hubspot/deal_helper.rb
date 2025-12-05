module Netsuite::Hubspot::DealHelper
  extend ActiveSupport::Concern

  included do
    def find_deal(filters, raise_error: true)
      payload = build_search_payload(filters)
      hs_deal = Hubspot::Deal.search(payload)

      raise "Hubspot deal not found" if raise_error && !object_present_with_id?(hs_deal)
      Rails.logger.info "************** Hubspot deal not found" unless object_present_with_id?(hs_deal)

      success_log("Found", hs_deal[:id]) if object_present_with_id?(hs_deal)
      hs_deal
    end

    def update_deal(payload)
      updated_deal = Hubspot::Deal.update(payload)

      raise "Failed to update Hubspot Deal" unless object_present_with_id?(updated_deal)

      success_log("Update", updated_deal[:id])
      updated_deal
    end

    def create_deal(payload)
      created_deal = Hubspot::Deal.create(payload)

      raise "Failed to create Hubspot Deal" unless object_present_with_id?(created_deal)

      success_log("Create", created_deal[:id])
      created_deal
    end

    private
      def success_log(work, hs_deal_id)
        Rails.logger.info "************** #{work} Hubspot Deal with ID #{hs_deal_id}"
      end
  end
end
