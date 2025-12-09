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

      info_log("Fetched Hubspot contact details")
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
          info_log("Searching Netsuite Contact by id")
          ns_contact = Netsuite::Contact.find_by_id(id: ns_contact_id)

          if ns_contact.present?
            info_log("Found Netsuite Contact by id #{ns_contact_id}")
            return "found by netsuite_contact_id"
          end
        end

        if email.present?
          payload = payload_to_create_netsuit_contact(hs_contact_details)
          find_or_create_ns_contact_by_email(payload, email)
        end
      end

      def update_hubspot_contact(hs_contact_details, ns_contact)
        update_hs_contact({
          contactId: hs_contact_details[:hs_object_id][:value],
          "netsuite_contact_id": (ns_contact[:id])
        })
      end

      def payload_to_create_netsuit_contact(contact_details)
        {
          "firstName": hs_value(contact_details, :firstname, "dummy"),
          "lastName": hs_value(contact_details, :lastname, "dummy"),
          "email": hs_value(contact_details, :email, "dummy"),
          "jobTitle":  hs_value(contact_details, :jobtitle, "dummy"),
          "isInactive": false,
          "mobilePhone": hs_value(contact_details, :phone, "0000000000"),
          "company": { "id": netsuite_company_id, "type": "customer" }
        }
      end
  end
end
