module Netsuite::Quote::Hubspot::ContactHelper
  extend ActiveSupport::Concern

  include Netsuite::Hubspot::ContactHelper

  included do
    def find_hubspot_contact
      find_contact(contact_filters)
    end

    def update_contact_info
      payload = payload_to_update_hubspot_contact(@hs_contact[:id])
      update_contact(payload)
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
  end
end
