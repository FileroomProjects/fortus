module Netsuite::SalesOrder::Hubspot::CompanyHelper
  extend ActiveSupport::Concern

  include Netsuite::Hubspot::CompanyHelper

  included do
    def find_hubspot_company
      find_company(filters)
    end

    private
      def filters
        [ build_search_filter("netsuite_company_id", "EQ", args[:customer][:id]) ]
      end
  end
end
