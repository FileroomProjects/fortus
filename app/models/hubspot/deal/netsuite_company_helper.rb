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
      raise "Hubspot Company details are blank" unless hs_company_details.present?

      info_log("Fetched Hubspot company details")
      ns_customer = find_or_create_netsuite_customer(hs_company_details)

      return if ns_customer == "found by netsuite_company_id" # No need to update hubspot company

      update_hubspot_company(hs_company_details, ns_customer) if object_present_with_id?(ns_customer)
    end

    private
      def find_or_create_netsuite_customer(hs_company_details)
        ns_company_id = hs_company_details[:netsuite_company_id]&.fetch("value", "")
        company_name = hs_company_details[:name]&.fetch("value", "")

        raise "Netsuite Company ID & name are blank in Hubspot company details" if ns_company_id.blank? && company_name.blank?

        if ns_company_id.present?
          info_log("Searching Netsuite Customer by id")
          ns_customer = Netsuite::Customer.find_by(columnName: "id", value: ns_company_id)

          if ns_customer.present?
            info_log("Found Netsuite Customer by id #{ns_company_id}")
            return "found by netsuite_company_id"
          end
        end

        if company_name.present?
          find_or_create_ns_customer_by_company_name(company_name)
        end
      end

      def update_hubspot_company(hs_company_details, ns_customer)
        update_hs_company({
          companyId: hs_company_details[:hs_object_id][:value],
          "netsuite_company_id": (ns_customer[:id])
        })
      end
  end
end
