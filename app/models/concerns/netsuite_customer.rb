module NetsuiteCustomer
  extend ActiveSupport::Concern

  included do
    # Find a NetSuite customer by company name or create one if missing.
    def find_or_create_ns_customer_by_company_name(company_name)
      Rails.logger.info "[INFO] [API.NETSUITE.CUSTOMER] [SEARCH] [company_name: #{company_name}] Searching netsuite customer with company name"
      customer = Netsuite::Customer.find_by(columnName: "companyname", value: company_name)

      if object_present_with_id?(customer)
        Rails.logger.info "[INFO] [API.HUBSPOT.CUSTOMER] [SEARCH] [customer_id: #{customer[:id]}, company_name: #{company_name}] HubSpot customer found with company name"
        return customer
      end

      Rails.logger.info "[INFO] [API.HUBSPOT.CUSTOMER] [SEARCH] [company_name: #{company_name}] Hubspot customer not found with company name"
      create_ns_customer(company_name)
    end

    def ns_customer_found_by_id?(ns_company_id)
      Rails.logger.info "[INFO] [API.NETSUITE.CUSTOMER] [SEARCH] [customer_id: #{ns_company_id}] Searching netsuite customer with id"
      ns_customer = Netsuite::Customer.find_by(columnName: "id", value: ns_company_id)

      if object_present_with_id?(ns_customer)
        Rails.logger.info "[INFO] [API.NETSUITE.CUSTOMER] [SEARCH] [customer_id: #{ns_customer[:id]}] Netsuite customer found with id"
        return true
      end

      Rails.logger.info "[INFO] [API.NETSUITE.CUSTOMER] [SEARCH] [customer_id: #{ns_company_id}] Netsuite customer not found with id"
      false
    end

    # Create a NetSuite customer using a default payload based on company name.
    def create_ns_customer(company_name)
      payload = create_customer_payload(company_name)
      customer = Netsuite::Customer.create(payload)
      process_response("Netsuite Customer", "create", customer)
    end

    def fetch_ns_customer(customer_id)
      Rails.logger.info "[INFO] [API.NETSUITE.CUSTOMER] [FETCH] [customer_id: #{customer_id}] Fetching netsuite customer details"
      customer = Netsuite::Customer.show(customer_id)
      process_response("Netsuite Customer details", "fetched", customer)
    end

    private
      # Build a default payload for creating a NetSuite customer.
      def create_customer_payload(company_name)
        {
          "companyName": company_name,
          "subsidiary": { "id": "22", "refName": "Fortus USA" },
          "category": { "id": "13", "refName": "4. Competitor - DEKK" },
          "custentity11": { "id": "80", "refName": "Aston - FU" }
        }
      end
  end
end
