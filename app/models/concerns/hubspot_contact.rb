module HubspotContact
  extend ActiveSupport::Concern

  included do
    def find_hs_contact(filters, raise_error: true)
      payload = build_search_payload(filters)
      contact = Hubspot::Contact.search(payload)

      if object_present_with_id?(contact)
        Rails.logger.info "[INFO] [API.HUBSPOT.CONTACT] [SEARCH] [contact_id: #{contact[:id]}] HubSpot contact found."
        contact
      else
        Rails.logger.info "[INFO] [API.HUBSPOT.CONTACT] [SEARCH] [filters: #{filters}] HubSpot contact not found"
        raise "Hubspot Contact not found" if raise_error
      end
    end

    def update_hs_contact(payload)
      updated_contact = Hubspot::Contact.update(payload)
      process_response("Hubspot Contact", "updated", updated_contact)
    end

    def create_hs_contact(payload)
      contact = Hubspot::Contact.create(payload)
      process_response("Hubspot Contact", "created", contact)
    end
  end
end
