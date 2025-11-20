module Netsuite::SalesOrder::Hubspot::ContactHelper
  extend ActiveSupport::Concern

  included do
    def fetch_hubspot_contact
      hs_contact = Hubspot::Contact.search(payload_for_search_hubspot_contact)
      if hs_contact.present? && hs_contact[:id].present?
        Rails.logger.info "************** Hubspot Contact found with ID #{hs_contact[:id]}"
        hs_contact
      else
        raise "Hubspot Contact not found"
      end
    end

    private
      def payload_for_search_hubspot_contact
        {
          filterGroups: [
            {
              filters: [
                {
                  propertyName: "netsuite_contact_id",
                  operator: "EQ",
                  value: args[:sales_order][:contact_id]
                }
              ]
            }
          ]
        }
      end
  end
end
