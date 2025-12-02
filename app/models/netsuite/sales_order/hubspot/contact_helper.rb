module Netsuite::SalesOrder::Hubspot::ContactHelper
  extend ActiveSupport::Concern

  include Netsuite::Hubspot::ContactHelper

  included do
    def find_hubspot_contact
      find_contact(contact_query)
    end

    private
      def contact_query
        [ build_search_filter("netsuite_contact_id", "EQ", args[:sales_order][:contact_id]) ]
      end
  end
end
