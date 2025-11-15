module Hubspot::Deal::NetsuiteContactHelper
  extend ActiveSupport::Concern

  included do
    def netsuite_contact_id
      associated_contact_details[:netsuite_contact_id][:value] 
    rescue
      raise "Netsuite Contact is blank"
    end

    def handle_contact_and_update_hubspot
      contact_details = associated_contact_details
      if contact_details.present?
        if contact_details[:netsuite_contact_id].present?
          if Netsuite::Contact.find_by_id(id: contact_details[:netsuite_contact_id].value)
            Rails.logger.info("Contact found in netsuite")
          end
          Rails.logger.info "************ netsuite_contact_id is present"
        else
          if contact_details[:email].present?
            ns_contact = Netsuite::Contact.find_by(email: contact_details["email"]["value"])
            if ns_contact.present?
              netsuite_contact_id = ns_contact["id"]
            else
              ns_contact = Netsuite::Contact.create(
                "firstName": contact_details[:firstname]&.fetch("value", ""),
                "lastName": "Doe",
                "email": contact_details[:email]&.fetch("value", ""),
                "jobTitle": contact_details[:jobtitle]&.fetch("value", ""),
                "isInactive": false,
                company: { "id": 123, "type": "customer" }
              )
              netsuite_contact_id = ns_contact[:id]
            end

            if ns_contact && netsuite_contact_id.present?
              Hubspot::Contact.update({
                contactId: contact_details[:hs_object_id][:value],
                "netsuite_contact_id": netsuite_contact_id
              })
            end
          else
            Rails.logger.error "Contact email or netsuite contact id is not present"
          end
        end
      else
        Rails.logger.log("************ Contact detail is blank")
      end
    end

  end
end
