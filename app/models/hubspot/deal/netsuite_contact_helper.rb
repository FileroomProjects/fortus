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

      raise "Hubspot Contact details are blank" unless hs_contact_details.present?

      Rails.logger.info "************** Fetched Hubspot contact details"
      ns_contact = find_or_create_netsuite_contact(hs_contact_details)

      return if ns_contact == "found by netsuite_contact_id" # No need to update hubspot contact

      update_hubspot_contact(hs_contact_details, ns_contact) if object_present_with_id?(ns_contact)
    end

    private
      def find_or_create_netsuite_contact(hs_contact_details)
        ns_contact_id = hs_contact_details[:netsuite_contact_id]&.fetch("value", "")
        email = hs_contact_details[:email]&.fetch("value", "")

        raise "Netsuite Contact ID & email are blank in Hubspot contact details" if ns_contact_id.blank? && email.blank?

        if ns_contact_id.present?
          Rails.logger.info "************** Searching Netsuite Contact by id"
          ns_contact = Netsuite::Contact.find_by_id(id: ns_contact_id)

          if ns_contact.present?
            Rails.logger.info "************** Found Netsuite Contact by id #{ns_contact_id}"
            return "found by netsuite_contact_id"
          end
        end

        if email.present?
          find_or_create_contact_by_email(hs_contact_details, email)
        end
      end

      def find_or_create_contact_by_email(hs_contact_details, email)
        Rails.logger.info "************** Searching Netsuite Contact by email"
        ns_contact = Netsuite::Contact.find_by(email: email)
        return ns_contact if ns_contact.present?

        Rails.logger.info "************** Creating Netsuite Contact"
        create_contact(hs_contact_details)
      end

      def update_hubspot_contact(hs_contact_details, ns_contact)
        Rails.logger.info "************** Updating Hubspot contact with netsuite_contact_id #{ns_contact[:id]}"
        Hubspot::Contact.update({
          contactId: hs_contact_details[:hs_object_id][:value],
          "netsuite_contact_id": (ns_contact[:id])
        })
      end

      def create_contact(contact_details)
        Netsuite::Contact.create(
          "firstName": hs_value(contact_details, :firstname, "dummy"),
          "lastName": hs_value(contact_details, :lastname, "dummy"),
          "email": hs_value(contact_details, :email, "dummy"),
          "jobTitle":  hs_value(contact_details, :jobtitle, "dummy"),
          "isInactive": false,
          "mobilePhone": hs_value(contact_details, :phone, "0000000000"),
          "company": { "id": netsuite_company_id, "type": "customer" }
        )
      end
  end
end
