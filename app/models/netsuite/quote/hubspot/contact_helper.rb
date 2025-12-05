module Netsuite::Quote::Hubspot::ContactHelper
  extend ActiveSupport::Concern

  include Netsuite::Hubspot::ContactHelper

  included do
    def update_or_create_hubspot_contact
      return nil unless args[:contact][:id].present?

      hs_contact = find_contact(contact_filters, raise_error: false)
      if object_present_with_id?(hs_contact)
        update_hubspot_contact(hs_contact)
      else
        create_hubspot_contact
      end
    end

    def update_hubspot_contact(hs_contact)
      payload = payload_to_update_hubspot_contact(hs_contact[:id])
      update_contact(payload)
    end

    def create_hubspot_contact
      payload = payload_to_create_hubspot_contact
      create_contact(payload)
    end

    private
      def contact_filters
        [
          build_search_filter("netsuite_contact_id", "EQ", args[:contact][:id])
        ]
      end

      def payload_to_update_hubspot_contact(hs_contact_id)
        {
          contactId: hs_contact_id,
          "firstname": args[:contact][:firstName],
          "lastname": args[:contact][:lastName],
          "email": args[:contact][:email],
          "jobtitle":  args[:contact][:jobTitle],
          "phone": args[:contact][:phone]
        }
      end

      def payload_to_create_hubspot_contact
        {
          "properties": {
            "firstname": args[:contact][:firstName],
            "lastname": args[:contact][:lastName],
            "email": args[:contact][:email],
            "jobtitle":  args[:contact][:jobTitle],
            "phone": args[:contact][:phone],
            "netsuite_contact_id": args[:contact][:id]
          }
        }
      end
  end
end
