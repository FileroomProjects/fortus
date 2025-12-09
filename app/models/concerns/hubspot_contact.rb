module HubspotContact
  extend ActiveSupport::Concern

  included do
    # Search for a HubSpot contact using provided filters.
    # - filters: Array of search filters.
    # - raise_error: whether to raise if no contact is found.
    def find_hs_contact(filters, raise_error: true)
      payload = build_search_payload(filters)
      contact = Hubspot::Contact.search(payload)
      process_response("Hubspot Contact", "found", contact, raise_error)
    end

    # Update a HubSpot contact using the given payload.
    def update_hs_contact(payload)
      updated_contact = Hubspot::Contact.update(payload)
      process_response("Hubspot Contact", "update", updated_contact)
    end

    # Create a HubSpot contact with the provided payload.
    def create_hs_contact(payload)
      contact = Hubspot::Contact.create(payload)
      process_response("Hubspot Contact", "create", contact)
    end
  end
end
