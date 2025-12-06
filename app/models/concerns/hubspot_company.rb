module HubspotCompany
  extend ActiveSupport::Concern

  included do
    def find_hs_company(filters, raise_error: true)
      payload = build_search_payload(filters)
      company = Hubspot::Company.search(payload)
      process_response("Hubspot Company", "found", company, raise_error)
    end

    def update_hs_company(payload)
      updated_company = Hubspot::Company.update(payload)
      process_response("Hubspot Company", "update", updated_company)
    end

    def create_hs_company(payload)
      company = Hubspot::Company.create(payload)
      process_response("Hubspot Company", "create", company)
    end
  end
end
