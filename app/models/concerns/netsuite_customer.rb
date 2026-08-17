module NetsuiteCustomer
  extend ActiveSupport::Concern

  included do
    # Find a NetSuite customer by company name or create one if missing.
    def find_or_create_ns_customer_by_company_name(hs_company_details)
      company_name = hs_value_for_company(hs_company_details, :name)

      Rails.logger.info "[INFO] [API.NETSUITE.CUSTOMER] [SEARCH] [company_name: #{company_name}] Searching netsuite customer with company name"
      customer = Netsuite::Customer.find_by(columnName: "companyname", value: company_name)

      if object_present_with_id?(customer)
        Rails.logger.info "[INFO] [API.HUBSPOT.CUSTOMER] [SEARCH] [customer_id: #{customer[:id]}, company_name: #{company_name}] HubSpot customer found with company name"
        update_ns_customer(customer[:id], hs_company_details)
        return fetch_ns_customer(customer[:id])
      end

      Rails.logger.info "[INFO] [API.HUBSPOT.CUSTOMER] [SEARCH] [company_name: #{company_name}] Hubspot customer not found with company name"
      create_ns_customer(hs_company_details)
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

    # Create a NetSuite customer using HubSpot company details + defaults.
    def create_ns_customer(hs_company_details)
      payload = create_customer_payload(hs_company_details)
      customer = Netsuite::Customer.create(payload)
      process_response("Netsuite Customer", "create", customer)
    end

    def update_ns_customer(ns_customer_id, hs_company_details)
      payload = Netsuite::CustomerFieldMapping.netsuite_payload_from_hubspot_company(hs_company_details)
      return if payload.blank?

      customer = Netsuite::Customer.update(ns_customer_id, payload)
      process_response("Netsuite Customer", "update", customer)
    end

    def fetch_ns_customer(customer_id)
      Rails.logger.info "[INFO] [API.NETSUITE.CUSTOMER] [FETCH] [customer_id: #{customer_id}] Fetching netsuite customer details"
      customer = Netsuite::Customer.show(customer_id)
      process_response("Netsuite Customer details", "fetched", customer)
    end

    # Merge webhook/partial customer data with full NetSuite customer record.
    def resolve_ns_customer(customer_args)
      customer_args = (customer_args || {}).with_indifferent_access
      return customer_args if customer_args[:id].blank?
      # Already a full REST payload (e.g. from Customer.show).
      return customer_args if customer_args[:companyName].present? || customer_args[:entityStatus].present?

      full_customer = Netsuite::Customer.show(customer_args[:id]) rescue nil
      return customer_args unless full_customer.present?

      full_customer.to_h.with_indifferent_access.merge(customer_args)
    end

    def hubspot_company_properties_from_ns_customer(customer, netsuite_company_id: nil)
      resolved = resolve_ns_customer(customer)
      Netsuite::CustomerFieldMapping.hubspot_properties_from_customer(
        resolved,
        netsuite_company_id: netsuite_company_id || resolved[:id]
      )
    end

    private
      def create_customer_payload(hs_company_details)
        company_name = hs_value_for_company(hs_company_details, :name)
        company_category = hs_value_for_company(hs_company_details, :category)
        mapped = Netsuite::CustomerFieldMapping.netsuite_payload_from_hubspot_company(hs_company_details)

        {
          "companyName": company_name,
          "subsidiary": { "id": "22", "refName": "Fortus USA" },
          "category": { "id": "13", "refName": "4. Competitor - DEKK" },
          "custentity11": { "id": "80", "refName": "Aston - FU" },
          "custentity49": { "id": "1", "refName": company_category }
        }.merge(mapped)
      end

      def hs_value_for_company(hs_company_details, key)
        Netsuite::CustomerFieldMapping.hubspot_field_value(hs_company_details, key.to_s).to_s
      end
  end
end
