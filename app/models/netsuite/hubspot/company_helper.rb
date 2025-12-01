module Netsuite::Hubspot::CompanyHelper
  extend ActiveSupport::Concern

  included do
    def find_company(filters)
      payload = build_search_payload(filters)
      hs_company = Hubspot::Company.search(payload)

      raise "Hubspot company not found" unless object_present_with_id?(hs_company)

      Rails.logger.info "************** Hubspot company found with ID #{hs_company[:id]}"
      hs_company
    end

    def update_company(payload)
      updated_hs_company = Hubspot::Company.update(payload)

      raise "Hubspot company not updated" unless object_present_with_id?(updated_hs_company)

      Rails.logger.info "************** Hubspot company update with ID #{updated_hs_company[:id]}"
      updated_hs_company
    end
  end
end
