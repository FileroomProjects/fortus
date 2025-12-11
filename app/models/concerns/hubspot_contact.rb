module HubspotContact
  extend ActiveSupport::Concern

  included do
    # Search for a HubSpot contact using provided filters.
    # - filters: Array of search filters.
    # - raise_error: whether to raise if no contact is found.
    def find_hs_contact(filters, raise_error: true)
      payload = build_search_payload(filters)
      contact = Hubspot::Contact.search(payload)

      if object_present_with_id?(contact)
        Rails.logger.info "[INFO] [API.HUBSPOT.CONTACT] [SEARCH] [contact_id: #{contact[:id]}] HubSpot contact found."
        contact
      end

      Rails.logger.info "[INFO] [API.HUBSPOT.CONTACT] [SEARCH] [filters: #{filters}] HubSpot contact not found"

      raise "Hubspot Contact not found" if raise_error
      nil
    end

    # Update a HubSpot contact using the given payload.
    def update_hs_contact(payload)
      updated_contact = Hubspot::Contact.update(payload)
      process_response("Hubspot Contact", "updated", updated_contact)
    end

    # Create a HubSpot contact with the provided payload.
    def create_hs_contact(payload)
      contact = Hubspot::Contact.create(payload)
      process_response("Hubspot Contact", "created", contact)
    end

    def hs_contact_sync_success_log(contact, action, ns_contact_id)
      Rails.logger.info "[INFO] [SYNC.NETSUITE_TO_HUBSPOT.CONTACT] [#{action}] [ns_contact_id: #{ns_contact_id}, hs_contact_id: #{contact[:id]}] Hubspot Contact #{action.downcase}d successfully"
      Rails.logger.info "[INFO] [SYNC.NETSUITE_TO_HUBSPOT.CONTACT] [COMPLETE] [ns_contact_id: #{ns_contact_id}, hs_contact_id: #{contact[:id]}] Nestuite Contact synchronized successfully"
      contact
    end
  end
end
