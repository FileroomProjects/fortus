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
          if Netsuite::Customer.find_by(columnName: "id", value: company_details[:netsuite_company_id]["value"])
            Rails.logger.info("Company found in netsuite")
          else
            create_and_update_company(company_details)
          end
          Rails.logger.info "************ netsuite_company_id is present"
        else
          create_and_update_company(company_details)
        end
      else
        Rails.logger.log("************ Company detail is blank")
      end
    end

    
    def create_and_update_company(company_details)
      if company_details[:name].present?
        ns_customer = Netsuite::Customer.find_by(columnName: "companyname", value: company_details[:name]&.fetch("value", ""))
        if ns_customer.present?
          netsuite_company_id = ns_customer["id"]
        else
          ns_customer = create_customer(company_details[:name]&.fetch("value", ""))
          netsuite_company_id = ns_customer[:id]
        end

        update_company(ns_customer, netsuite_company_id)
      else
       Rails.logger.error "Company email or netsuite company id is not present"
      end
    end

   

    def create_customer(name)
      Netsuite::Customer.create(
        "companyName": name,
        "subsidiary": { "id": "8", "refName": "Dekk Rubber Tracks and Pads" },
        "category": { "id": "13", "refName": "4. Competitor - DEKK" },
        "custentity11": { "id": "80", "refName": "Aston - FU" }
      )
    end

    def update_company(ns_customer, netsuite_company_id)
      if ns_customer && netsuite_company_id.present?
        Hubspot::Company.update({
          companyId: company_details[:hs_object_id][:value],
          "netsuite_company_id": netsuite_company_id
        })
      end
    end

    # def handle_company_and_update_hubspot
    #   company_details = associated_company_details
    #   if company_details.present?
    #     if company_details[:netsuite_company_id].present?
    #       if Netsuite::Customer.find_by_id(id: contact_details[:netsuite_company_id].value)
    #         Rails.logger.info("Contact found in netsuite")
    #       end
    #       Rails.logger.info "************ netsuite_customer_id is present"
    #     else
    #       ns_customer = Netsuite::Customer.create(
    #         "firstName": company_details[:firstname]&.fetch("value", ""),
    #         "lastName": "Doe",
    #         "email": company_details[:email]&.fetch("value", ""),
    #         "jobTitle": company_details[:jobtitle]&.fetch("value", ""),
    #         "isInactive": false,
    #         company: { "id": 123, "type": "customer" }
    #       )
    #       # netsuite_customer_id = ns_customer[:id]
    #     end
    #     # if netsuite_customer_id.present?
    #     #   Hubspot::Company.update({
    #     #     companyId: customer_details[:hs_object_id][:value],
    #     #     "netsuite_customer_id": netsuite_customer_id
    #     #   })
    #     # end
    #   else
    #     Rails.logger.log("************ Company detail is blank")
    #   end
    # end
  end
end
