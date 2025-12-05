module Netsuite::Hubspot::CompanyHelper
  extend ActiveSupport::Concern

  included do
    def find_company(filters, raise_error: true)
      payload = build_search_payload(filters)
      company = Hubspot::Company.search(payload)

      raise "Hubspot company not found" if raise_error && !object_present_with_id?(company)
      Rails.logger.info "************** Hubspot company not found" unless object_present_with_id?(company)

      company_success_log("Found", company[:id]) if object_present_with_id?(company)
      company
    end

    def update_company(payload)
      updated_company = Hubspot::Company.update(payload)

      raise "Hubspot company not updated" unless object_present_with_id?(updated_company)

      company_success_log("Updated", updated_company[:id])
      updated_company
    end

    def create_company(payload)
      company = Hubspot::Company.create(payload)

      raise "Hubspot company not created" unless object_present_with_id?(company)

      company_success_log("Created", company[:id])
      company
    end

    private
      def company_success_log(action, company_id)
        Rails.logger.info "************** #{action} Hubspot Company with ID #{company_id}"
      end
  end
end
