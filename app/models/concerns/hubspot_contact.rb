module HubspotContact
  extend ActiveSupport::Concern

  included do
    def find_hs_contact(filters, raise_error: true)
      payload = build_search_payload(filters)
      contact = Hubspot::Contact.search(payload)
      process_response("Hubspot Contact", "found", contact, raise_error)
    end

    def update_hs_contact(payload)
      updated_contact = Hubspot::Contact.update(payload)
      process_response("Hubspot Contact", "update", updated_contact)
    end

    def create_hs_contact(payload)
      contact = Hubspot::Contact.create(payload)
      process_response("Hubspot Contact", "create", contact)
    end
  end
end
