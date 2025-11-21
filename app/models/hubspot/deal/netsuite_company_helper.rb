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
      if hs_company_details.present?
        Rails.logger.info "************** Fetched Hubspot company details"
        ns_customer = find_or_create_netsuite_customer(hs_company_details)

        return if ns_customer == "found by netsuite_company_id" # No need to update hubspot company

        if ns_customer.present?
          Rails.logger.info "************** Updating hubspot company with netsuite_company_id #{ns_customer&.fetch(:id, "")}"
          Hubspot::Company.update({
            companyId: hs_company_details[:hs_object_id][:value],
            "netsuite_company_id": (ns_customer&.fetch(:id, ""))
          })
        else
          raise "Netsuite Company ID & name are blank in Hubspot company details"
        end
      else
        Rails.logger.info "************ Company details are blank in hubspot"
        raise "Hubspot Company details are blank"
      end
    end

    def find_or_create_netsuite_customer(hs_company_details)
      ns_company_id = hs_company_details[:netsuite_company_id]&.fetch("value", "")
      company_name = hs_company_details[:name]&.fetch("value", "")
      ns_customer = nil

      if ns_company_id.present?
        Rails.logger.info "************** Searching Netsuite Customer by id"
        ns_customer = Netsuite::Customer.find_by(columnName: "id", value: ns_company_id)
        if ns_customer.present?
          Rails.logger.info "************** Found Netsuite Customer by id #{ns_company_id}"
          return "found by netsuite_company_id"
        end
      end

      if company_name.present?
        Rails.logger.info "************** Searching Netsuite Customer by company name"
        ns_customer = Netsuite::Customer.find_by(columnName: "companyname", value: company_name)
      end

      if ns_customer.blank? && company_name.present?
        Rails.logger.info "************** Creating Netsuite Customer"
        ns_customer = create_customer(company_name)
      end

      ns_customer
    end

    def create_customer(company_name)
      Netsuite::Customer.create(
        "companyName": company_name,
        "subsidiary": { "id": "22", "refName": "Fortus USA" },
        "category": { "id": "13", "refName": "4. Competitor - DEKK" },
        "custentity11": { "id": "80", "refName": "Aston - FU" }
      )
    end
  end
end
