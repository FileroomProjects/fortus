module NetsuiteContact
  extend ActiveSupport::Concern

  included do
    # Find a NetSuite contact by email or name, or create one if not found.
    # - payload: payload used to create the contact when missing
    # - email: email address to search for
    def find_or_create_ns_contact_by_email(payload, email)
      Rails.logger.info "[INFO] [API.NETSUITE.CONTACT] [SEARCH] [email: #{email}] Searching netsuite contact with email"
      contact = Netsuite::Contact.find_by(email: email)

      if object_present_with_id?(contact)
        Rails.logger.info "[INFO] [API.NETSUITE.CONTACT] [SEARCH] [contact_id: #{contact[:id]}] Netsuite contact found with email"
        return contact
      end

      Rails.logger.info "[INFO] [API.NETSUITE.CONTACT] [SEARCH] [email: #{email}] Netsuite contact not found with email"

      contact = find_ns_contact_by_name(payload["firstName"] || payload[:firstName], payload["lastName"] || payload[:lastName])
      if object_present_with_id?(contact)
        Rails.logger.info "[INFO] [API.NETSUITE.CONTACT] [SEARCH] [contact_id: #{contact[:id]}] Netsuite contact found with name"
        sync_existing_ns_contact(contact[:id], payload)
        return contact
      end

      create_ns_contact_or_reuse_by_name(payload)
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

    private
      def find_ns_contact_by_name(first_name, last_name)
        return nil if first_name.blank? || last_name.blank?
        return nil if first_name.to_s.downcase == "dummy" && last_name.to_s.downcase == "dummy"

        Rails.logger.info "[INFO] [API.NETSUITE.CONTACT] [SEARCH] [first_name: #{first_name}, last_name: #{last_name}] Searching netsuite contact with name"
        Netsuite::Contact.find_by(firstName: first_name, lastName: last_name)
      end

      def create_ns_contact_or_reuse_by_name(payload)
        create_ns_contact(payload)
      rescue RuntimeError => e
        raise unless unique_contact_name_error?(e)

        contact = find_ns_contact_by_name(payload["firstName"] || payload[:firstName], payload["lastName"] || payload[:lastName])
        raise e unless object_present_with_id?(contact)

        Rails.logger.info "[INFO] [API.NETSUITE.CONTACT] [SEARCH] [contact_id: #{contact[:id]}] Reusing existing netsuite contact after unique name conflict"
        sync_existing_ns_contact(contact[:id], payload)
        contact
      end

      def unique_contact_name_error?(error)
        message = error.message.to_s
        message.include?("unique name") || message.include?("already exists")
      end

      def sync_existing_ns_contact(ns_contact_id, payload)
        update_payload = {
          "email" => payload["email"] || payload[:email],
          "mobilePhone" => payload["mobilePhone"] || payload[:mobilePhone],
          "jobTitle" => payload["jobTitle"] || payload[:jobTitle],
          "company" => payload["company"] || payload[:company]
        }.compact
        return if update_payload.blank?

        Netsuite::Contact.update(ns_contact_id, update_payload)
      rescue RuntimeError => e
        Rails.logger.warn "[WARN] [API.NETSUITE.CONTACT] [UPDATE] [contact_id: #{ns_contact_id}] Failed to update existing contact: #{e.message}"
      end
  end
end
