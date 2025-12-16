module HubspotCompany
  extend ActiveSupport::Concern

  included do
    # Search for a HubSpot company using provided filters.
    # - filters: Array of search filters
    # - raise_error: whether to raise if no company is found
    def find_hs_company(filters, raise_error: true)
      payload = build_search_payload(filters)
      company = Hubspot::Company.search(payload)

      if object_present_with_id?(company)
        Rails.logger.info "[INFO] [API.HUBSPOT.COMPANY] [SEARCH] [company_id: #{company[:id]}] HubSpot company found"
        return company
      end

      Rails.logger.info "[INFO] [API.HUBSPOT.COMPANY] [SEARCH] [filters: #{filters}] HubSpot company not found"

      raise "Hubspot Company not found" if raise_error
      nil
    end

    # Update a HubSpot company with the given payload.
    def update_hs_company(payload)
      updated_company = Hubspot::Company.update(payload)
      process_response("Hubspot Company", "updated", updated_company)
    end

    # Create a new HubSpot company from the provided payload.
    def create_hs_company(payload)
      company = Hubspot::Company.create(payload)
      process_response("Hubspot Company", "created", company)
    end

    def hs_company_sync_success_log(company, action, ns_customer_id)
      Rails.logger.info "[INFO] [SYNC.NETSUITE_TO_HUBSPOT.CUSTOMER] [#{action}] [customer_id: #{ns_customer_id}, company_id: #{company[:id]}] Company #{action.downcase}d successfully"
      Rails.logger.info "[INFO] [SYNC.NETSUITE_TO_HUBSPOT.CUSTOMER] [COMPLETE] [customer_id: #{ns_customer_id}, company_id: #{company[:id]}] Customer synchronized successfully"
      company
    end
  end
end
