module HubspotCompany
  extend ActiveSupport::Concern

  included do
    def find_hs_company(filters, raise_error: true)
      payload = build_search_payload(filters)
      company = Hubspot::Company.search(payload)

      if object_present_with_id?(company)
        Rails.logger.info "[INFO] [API.HUBSPOT.COMPANY] [SEARCH] [company_id: #{company[:id]}] HubSpot company found"
        company
      else
        Rails.logger.info "[INFO] [API.HUBSPOT.COMPANY] [SEARCH] [filters: #{filters}] HubSpot company not found"
        raise "Hubspot Company not found" if raise_error
        nil
      end
    end

    def update_hs_company(payload)
      updated_company = Hubspot::Company.update(payload)
      process_response("Hubspot Company", "updated", updated_company)
    end

    def create_hs_company(payload)
      company = Hubspot::Company.create(payload)
      process_response("Hubspot Company", "created", company)
    end
  end
end
