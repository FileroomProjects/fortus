module Netsuite::Estimate::Hubspot::ContactHelper
  extend ActiveSupport::Concern

  included do
    def update_or_create_hubspot_contact
      return nil unless args[:contact][:id].present?

      hs_contact = find_hubspot_contact
      if object_present_with_id?(hs_contact)
        update_hubspot_contact(hs_contact)
      else
        create_hubspot_contact
      end
    end

    # Try to find by id first, then by email; return first match
    def find_hubspot_contact
      [
        [ :id,    :build_contact_filter_with_id ],
        [ :email, :build_contact_filter_with_email ]
      ].each do |key, builder|
        next unless args[:contact][key].present?
        hs_contact = find_hs_contact(send(builder), raise_error: false)
        return hs_contact if object_present_with_id?(hs_contact)
      end

      nil
    end

    def update_hubspot_contact(hs_contact)
      payload = payload_to_update_hubspot_contact(hs_contact[:id])
      update_hs_contact(payload)
    end

    def create_hubspot_contact
      payload = payload_to_create_hubspot_contact
      create_hs_contact(payload)
    end

    private
      def build_contact_filter_with_id
        [
          build_search_filter("netsuite_contact_id", "EQ", args[:contact][:id])
        ]
      end

      def build_contact_filter_with_email
        [
          build_search_filter("email", "EQ", args[:contact][:email])
        ]
      end

      def payload_to_update_hubspot_contact(hs_contact_id)
        {
          contactId: hs_contact_id,
          "firstname": args[:contact][:firstName],
          "lastname": args[:contact][:lastName],
          "email": args[:contact][:email],
          "jobtitle":  args[:contact][:jobTitle],
          "phone": args[:contact][:phone],
          "netsuite_contact_id": args[:contact][:id]
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
