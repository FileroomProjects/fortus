module Netsuite::Hubspot::ContactHelper
  extend ActiveSupport::Concern

  included do
    def find_contact(filters, raise_error: true)
      payload = build_search_payload(filters)
      contact = Hubspot::Contact.search(payload)

      raise "Hubspot Contact not found" if raise_error && !object_present_with_id?(contact)
      Rails.logger.info "************** Hubspot Contact not found" unless object_present_with_id?(contact)

      contact_success_log("Found", contact[:id]) if object_present_with_id?(contact)
      contact
    end

    def update_contact(payload)
      updated_contact = Hubspot::Contact.update(payload)

      raise "Hubspot Contact not updated" unless object_present_with_id?(updated_contact)

      contact_success_log("Updated", updated_contact[:id])
      updated_contact
    end

    def create_contact(payload)
      contact = Hubspot::Contact.create(payload)

      raise "Hubspot Contact not created" unless object_present_with_id?(contact)

      contact_success_log("Created", contact[:id])
      contact
    end

    private
      def contact_success_log(action, contact_id)
        Rails.logger.info "************** #{action} Hubspot Contact with ID #{contact_id}"
      end
  end
end
