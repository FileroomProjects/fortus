module NetsuiteContact
  extend ActiveSupport::Concern

  included do
    # Find a NetSuite contact by email or create one if not found.
    # - payload: payload used to create the contact when missing
    # - email: email address to search for
    def find_or_create_ns_contact_by_email(payload, email)
      contact = Netsuite::Contact.find_by(email: email)

      return create_ns_contact(payload) unless object_present_with_id?(contact)

      info_log("Found Netsuite Contact with ID #{contact[:id]}")
      contact
    end

    # Create a NetSuite contact using the provided payload.
    def create_ns_contact(payload)
      contact = Netsuite::Contact.create(payload)
      process_response("Netsuite Contact", "create", contact)
    end
  end
end
