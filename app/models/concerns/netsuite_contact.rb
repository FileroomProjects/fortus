module NetsuiteContact
  extend ActiveSupport::Concern

  included do
    def find_or_create_ns_contact_by_emai(payload, email)
      contact = Netsuite::Contact.find_by(email: email)

      return create_ns_contact(payload) unless object_present_with_id?(contact)

      info_log("Found Netsuite Contact with ID #{contact[:id]}")
      contact
    end

    def create_ns_contact(payload)
      contact = Netsuite::Contact.create(payload)
      process_response("Netsuite Contact", "create", contact)
    end
  end
end
