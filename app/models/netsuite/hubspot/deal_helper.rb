module Netsuite::Hubspot::DealHelper
  extend ActiveSupport::Concern

  included do
    def find_deal(filters)
      payload = build_search_payload(filters)
      hs_deal = ::Hubspot::Deal.search(payload)

      raise "Hubspot quote deal not found" unless object_present_with_id?(hs_deal)

      Rails.logger.info "************** Hubspot quote deal found ID #{hs_deal[:id]}"
      hs_deal
    end

    def update_deal(payload)
      updated_deal = Hubspot::Deal.update(payload)

      raise "Failed to update Hubspot Deal" unless object_present_with_id?(updated_deal)

      Rails.logger.info "************** Updated Hubspot Deal with ID #{updated_deal[:id]}"
      updated_deal
    end
  end
end
