module Netsuite::SalesOrder::Hubspot::ContactHelper
  extend ActiveSupport::Concern

  included do
    def find_hubspot_contact
      find_hs_contact(contact_query)
    end

    private
      def contact_query
        [ build_search_filter("netsuite_contact_id", "EQ", args[:sales_order][:contact_id]) ]
      end
  end
end
