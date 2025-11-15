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
        ns_company_id = hs_company_details[:netsuite_company_id]&.fetch("value", "")

        if ns_company_id.present?
          ns_customer = Netsuite::Customer.find_by(columnName: "id", value: ns_company_id)
        end
        
        if ns_customer.blank? && hs_company_details[:name].present?
          ns_customer = Netsuite::Customer.find_by(columnName: "companyname", value: hs_company_details[:name]&.fetch("value", ""))
        end

        if ns_customer.blank? && hs_company_details[:name].present?
          ns_customer = create_customer(hs_company_details[:name]&.fetch("value", ""))
        end

        if ns_customer.present?
          Hubspot::Company.update({
            companyId: hs_company_details[:hs_object_id][:value],
            "netsuite_company_id": ns_customer[:id]
          })
        else
          Rails.logger.info "askfhjk"
        end

      else
        Rails.logger.log("************ Company detail is blank in hubspot")
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
