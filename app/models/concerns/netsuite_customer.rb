module NetsuiteCustomer
  extend ActiveSupport::Concern

  included do
    def find_or_create_ns_customer_by_company_name(company_name)
      Rails.logger.info "[INFO] [API.NETSUITE.CUSTOMER] [SEARCH] [company_name: #{company_name}] Searching netsuite customer with company name"
      customer = Netsuite::Customer.find_by(columnName: "companyname", value: company_name)

      if object_present_with_id?(customer)
        Rails.logger.info "[INFO] [API.HUBSPOT.CUSTOMER] [SEARCH] [customer_id: #{customer[:id]}, company_name: #{company_name}] HubSpot customer found with company name"
        customer
      else
        Rails.logger.info "[INFO] [API.HUBSPOT.CUSTOMER] [SEARCH] [company_name: #{company_name}] Hubspot customer not found with company name"
        create_ns_customer(company_name)
      end
    end

    def create_ns_customer(company_name)
      payload = create_customer_payload(company_name)
      customer = Netsuite::Customer.create(payload)
      process_response("Netsuite Customer", "create", customer)
    end

    private
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
