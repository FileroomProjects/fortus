module NetsuiteCustomer
  extend ActiveSupport::Concern

  included do
    def find_or_create_ns_customer_by_company_name(company_name)
      customer = Netsuite::Customer.find_by(columnName: "companyname", value: company_name)

      return create_ns_customer(company_name) unless object_present_with_id?(customer)

      info_log("Found Netsuite Customer with ID #{customer[:id]}")
      customer
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
