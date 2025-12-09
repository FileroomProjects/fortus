module NetsuiteContact
  extend ActiveSupport::Concern

  included do
    def find_or_create_ns_contact_by_email(payload, email)
      Rails.logger.info "[INFO] [API.NETSUITE.CONTACT] [SEARCH] [email: #{email}] Searching hubspot contact with email"
      contact = Netsuite::Contact.find_by(email: email)

      if object_present_with_id?(contact)
        Rails.logger.info "[INFO] [API.HUBSPOT.CONTACT] [SEARCH] [contact_id: #{contact[:id]}] HubSpot contact found with email"
        contact
      else
        Rails.logger.info "[INFO] [API.HUBSPOT.CONTACT] [SEARCH] [email: #{email}] Hubspot contact not found with email"
        create_ns_contact(payload)
      end
    end

    def create_ns_contact(payload)
      contact = Netsuite::Contact.create(payload)
      process_response("Netsuite Contact", "create", contact)
    end
  end
end
