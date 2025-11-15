module Hubspot::Deal::NetsuiteCompanyHelper
  extend ActiveSupport::Concern

  included do
    def netsuite_company_id
      associated_company_details[:netsuite_company_id][:value] 
    rescue
      raise "Netsuite Company is blank"
    end

    def handle_company_and_update_hubspot
      company_details = associated_company_details
      if company_details.present?
        if company_details[:netsuite_company_id].present?
          if Netsuite::Customer.find_by_id(id: contact_details[:netsuite_company_id].value)
            Rails.logger.info("Contact found in netsuite")
          end
          Rails.logger.info "************ netsuite_customer_id is present"
        else
          ns_customer = Netsuite::Customer.create(
            "firstName": company_details[:firstname]&.fetch("value", ""),
            "lastName": "Doe",
            "email": company_details[:email]&.fetch("value", ""),
            "jobTitle": company_details[:jobtitle]&.fetch("value", ""),
            "isInactive": false,
            company: { "id": 123, "type": "customer" }
          )
          # netsuite_customer_id = ns_customer[:id]
        end
        # if netsuite_customer_id.present?
        #   Hubspot::Company.update({
        #     companyId: customer_details[:hs_object_id][:value],
        #     "netsuite_customer_id": netsuite_customer_id
        #   })
        # end
      else
        Rails.logger.log("************ Company detail is blank")
      end
    end
  end
end
