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

      ns_contact = find_or_create_netsuite_contact(hs_contact_details)

      return if ns_contact == "found by netsuite_contact_id" # No need to update hubspot contact

      if object_present_with_id?(ns_contact)
        Rails.logger.info "[INFO] [SYNC.HUBSPOT_TO_NETSUITE.CONTACT] [CREATE] [hs_contact_id: #{hs_contact_details[:hs_object_id][:value]}, ns_contact_id: #{ns_contact[:id]}] Netsuite contact created successfully"
        updated_contact = update_hubspot_contact(hs_contact_details, ns_contact)
        if object_present_with_id?(updated_contact)
          Rails.logger.info "[INFO] [SYNC.HUBSPOT_TO_NETSUITE.CONTACT] [UPDATE] [hs_contact_id: #{updated_contact[:id]}, ns_contact_id: #{ns_contact[:id]}] HubSpot contact updated successfully"
          Rails.logger.info "[INFO] [SYNC.HUBSPOT_TO_NETSUITE.CONTACT] [COMPLETE] [hs_contact_id: #{updated_contact[:id]}, ns_contact_id: #{ns_contact[:id]}] Contact synchronized successfully"
        end
      end
    end

    private
      def find_or_create_netsuite_contact(hs_contact_details)
        ns_contact_id = hs_contact_details[:netsuite_contact_id]&.fetch("value", "")
        email = hs_contact_details[:email]&.fetch("value", "")

        raise "Netsuite Contact ID & email are blank in Hubspot contact details" if ns_contact_id.blank? && email.blank?

        Rails.logger.info "[INFO] [SYNC.HUBSPOT_TO_NETSUITE.CONTACT] [START] [hs_contact_id: #{hs_contact_details[:hs_object_id][:value]}] Initiating contact synchronization"
        if ns_contact_id.present?
          Rails.logger.info "[INFO] [API.NETSUITE.CONTACT] [SEARCH] [contact_id: #{ns_contact_id}] Searching netsuite contact with id"
          ns_contact = Netsuite::Contact.find_by_id(id: ns_contact_id)

          if object_present_with_id?(ns_contact)
            Rails.logger.info "[INFO] [API.NETSUITE.CONTACT] [SEARCH] [contact_id: #{ns_contact[:id]}] Netsuite contact found with id"
            return "found by netsuite_contact_id"
          else
            Rails.logger.info "[INFO] [API.NETSUITE.CONTACT] [SEARCH] [contact_id: #{ns_contact_id}] Netsuite contact not found with id"
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
