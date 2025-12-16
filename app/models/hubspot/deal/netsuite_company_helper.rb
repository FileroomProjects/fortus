module Hubspot::Deal::NetsuiteCompanyHelper
  extend ActiveSupport::Concern

  included do
    def netsuite_company_id
      associated_company_details[:netsuite_company_id][:value]
    rescue
      raise "Netsuite Company is blank"
    end

    def handle_company_and_update_hubspot
      hs_company_details = associated_company_details # fetch from hs

      ns_customer = find_or_create_netsuite_customer(hs_company_details)

      return if ns_customer == "found by id" # No need to update hubspot company

      Rails.logger.info "[INFO] [SYNC.HUBSPOT_TO_NETSUITE.COMPANY] [CREATE] [company_id: #{company_id(hs_company_details)}, customer_id: #{ns_customer[:id]}] Netsuite customer created successfully"
      updated_company = update_hubspot_company(hs_company_details, ns_customer)

      Rails.logger.info "[INFO] [SYNC.HUBSPOT_TO_NETSUITE.COMPANY] [UPDATE] [company_id: #{updated_company[:id]}, customer_id: #{ns_customer[:id]}] HubSpot company updated successfully"
      Rails.logger.info "[INFO] [SYNC.HUBSPOT_TO_NETSUITE.COMPANY] [COMPLETE] [company_id: #{updated_company[:id]}, customer_id: #{ns_customer[:id]}] Company synchronized successfully"
    end

    private
      def find_or_create_netsuite_customer(hs_company_details)
        ns_company_id = hs_company_details[:netsuite_company_id]&.fetch("value", "")
        company_name = hs_company_details[:name]&.fetch("value", "")

        raise "Netsuite Company ID & name are blank in Hubspot company details" if ns_company_id.blank? && company_name.blank?

        Rails.logger.info "[INFO] [SYNC.HUBSPOT_TO_NETSUITE.COMPANY] [START] [company_id: #{company_id(hs_company_details)}] Initiating company synchronization"

        return "found by id" if ns_company_id.present? && ns_customer_found_by_id?(ns_company_id)

        return find_or_create_ns_customer_by_company_name(company_name) if company_name.present?

        raise "Netsuite Company name is missing in Hubspot company details & no customer was found by netsuite_company_id: #{ns_company_id}"
      end

      def update_hubspot_company(hs_company_details, ns_customer)
        update_hs_company({
          companyId: company_id(hs_company_details),
          "netsuite_company_id": (ns_customer[:id])
        })
      end

      def company_id(hs_company_details)
        hs_company_details[:hs_object_id]&.fetch("value", "")
      end
  end
end
