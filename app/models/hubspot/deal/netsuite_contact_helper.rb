module Hubspot::Deal::NetsuiteContactHelper
  extend ActiveSupport::Concern

  included do
    def netsuite_contact_id
      associated_contact_details[:netsuite_contact_id][:value]
    rescue
      raise "Netsuite Contact is blank"
    end

    def handle_contact_and_update_hubspot
      hs_contact_details = associated_contact_details
      if hs_contact_details.present?
        Rails.logger.info "************** Fetched Hubspot contact details"
        ns_contact_id = hs_contact_details[:netsuite_contact_id]&.fetch("value", "")

        if ns_contact_id.present?
          Rails.logger.info "************** Searching Netsuite Contact by id"
          ns_contact = Netsuite::Contact.find_by_id(id: hs_contact_details[:netsuite_contact_id]["value"])
        end

        if ns_contact.blank? && hs_contact_details[:email].present?
          Rails.logger.info "************** Searching Netsuite Contact by email"
          ns_contact = Netsuite::Contact.find_by(email: hs_contact_details["email"]["value"])
        end

        if ns_contact.blank? && hs_contact_details[:email].present?
          Rails.logger.info "************** Creating Netsuite Contact"
          ns_contact = create_contact(hs_contact_details)
        end

        if ns_contact.present?
          Rails.logger.info "************** Updating Hubspot contact with netsuite_contact_id #{ns_contact&.fetch(:id, "")}"
          Hubspot::Contact.update({
            contactId: hs_contact_details[:hs_object_id][:value],
            "netsuite_contact_id": (ns_contact&.fetch(:id, ""))
          })
        else
          Rails.logger.info "************** Netsuite Contact ID & email are blank in Hubspot contact details"
        end

      else
        Rails.logger.info "************ Contact details are blank in Hubspot"
      end
    end

    def create_contact(contact_details)
      Netsuite::Contact.create(
        "firstName": contact_details[:firstname]&.fetch("value", ""),
        "lastName": "Doe",
        "email": contact_details[:email]&.fetch("value", ""),
        "jobTitle": contact_details[:jobtitle]&.fetch("value", ""),
        "isInactive": false,
        "company": { "id": netsuite_company_id, "type": "customer" }
      )
    end
  end
end
