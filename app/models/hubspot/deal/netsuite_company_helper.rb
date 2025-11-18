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
        ns_company_id = hs_company_details[:netsuite_company_id]&.fetch("value", "")

        if ns_company_id.present?
          Rails.logger.info "************** Searching Netsuite Customer by id"
          ns_customer = Netsuite::Customer.find_by(columnName: "id", value: ns_company_id)
          if ns_customer.present?
            Rails.logger.info "************** Found Netsuite Customer by id #{ns_company_id}"
            return
          end
        end

        if ns_customer.blank? && hs_company_details[:name].present?
          Rails.logger.info "************** Searching Netsuite Customer by company name"
          ns_customer = Netsuite::Customer.find_by(columnName: "companyname", value: hs_company_details[:name]&.fetch("value", ""))
        end

        if ns_customer.blank? && hs_company_details[:name].present?
          Rails.logger.info "************** Creating Netsuite Customer"
          ns_customer = create_customer(hs_company_details[:name]&.fetch("value", ""))
        end

        if ns_customer.present?
          Rails.logger.info "************** Updating hubspot company with netsuite_company_id #{ns_customer&.fetch(:id, "")}"
          Hubspot::Company.update({
            companyId: hs_company_details[:hs_object_id][:value],
            "netsuite_company_id": (ns_customer&.fetch(:id, ""))
          })
        else
          Rails.logger.info "************** Netsuite Company ID & name are blank in hubspot company details"
        end

      else
        Rails.logger.info "************ Company details are blank in hubspot"
      end
    end

    def create_customer(name)
      Netsuite::Customer.create(
        "companyName": name,
        "subsidiary": { "id": "22", "refName": "Fortus USA" },
        "category": { "id": "13", "refName": "4. Competitor - DEKK" },
        "custentity11": { "id": "80", "refName": "Aston - FU" }
      )
    end
  end
end
