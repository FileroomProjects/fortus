module Netsuite::Hubspot::ContactHelper
  extend ActiveSupport::Concern

  included do
    def find_contact(filters)
      payload = build_search_payload(filters)
      hs_contact = Hubspot::Contact.search(payload)

      raise "Hubspot Contact not found" unless object_present_with_id?(hs_contact)

      Rails.logger.info "************** Hubspot Contact found with ID #{hs_contact[:id]}"
      hs_contact
    end

    def update_contact(payload)
      updated_hs_contact = Hubspot::Contact.update(payload)

      raise "Hubspot Contact not updated" unless object_present_with_id?(updated_hs_contact)

      Rails.logger.info "************** Hubspot Contact update with ID #{updated_hs_contact[:id]}"
      updated_hs_contact
    end
  end
end
