module Netsuite::Quote::Hubspot::ContactHelper
  extend ActiveSupport::Concern

  include Netsuite::Hubspot::ContactHelper

  included do
    def update_contact_info
      hs_contact = find_contact(filters)
      payload = payload_to_update_hubspot_contact(hs_contact[:id])
      update_contact(payload)
    end

    private
      def filters
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
          "phone": args[:contact][:mobilePhone]
        }
      end
  end
end
