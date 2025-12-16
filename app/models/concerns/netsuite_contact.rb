module NetsuiteContact
  extend ActiveSupport::Concern

  included do
    # Find a NetSuite contact by email or create one if not found.
    # - payload: payload used to create the contact when missing
    # - email: email address to search for
    def find_or_create_ns_contact_by_email(payload, email)
      Rails.logger.info "[INFO] [API.NETSUITE.CONTACT] [SEARCH] [email: #{email}] Searching hubspot contact with email"
      contact = Netsuite::Contact.find_by(email: email)

      if object_present_with_id?(contact)
        Rails.logger.info "[INFO] [API.HUBSPOT.CONTACT] [SEARCH] [contact_id: #{contact[:id]}] HubSpot contact found with email"
        return contact
      end

      Rails.logger.info "[INFO] [API.HUBSPOT.CONTACT] [SEARCH] [email: #{email}] Hubspot contact not found with email"
      create_ns_contact(payload)
    end

    def ns_contact_found_by_id?(ns_contact_id)
      Rails.logger.info "[INFO] [API.NETSUITE.CONTACT] [SEARCH] [contact_id: #{ns_contact_id}] Searching netsuite contact with id"
      contact = Netsuite::Contact.find_by_id(id: ns_contact_id)

      if object_present_with_id?(contact)
        Rails.logger.info "[INFO] [API.NETSUITE.CONTACT] [SEARCH] [contact_id: #{contact[:id]}] Netsuite contact found with id"
        return true
      end

      Rails.logger.info "[INFO] [API.NETSUITE.CONTACT] [SEARCH] [contact_id: #{ns_contact_id}] Netsuite contact not found with id"
      false
    end

    # Create a NetSuite contact using the provided payload.
    def create_ns_contact(payload)
      contact = Netsuite::Contact.create(payload)
      process_response("Netsuite Contact", "create", contact)
    end
  end
end
