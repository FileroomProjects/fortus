module Netsuite::SalesOrder::Hubspot::CompanyHelper
  extend ActiveSupport::Concern

  included do
    def find_hubspot_company
      filters = company_search_filters
      find_hs_company(filters)
    end

    private
      def company_search_filters
        [ build_search_filter("netsuite_company_id", "EQ", args[:customer][:id]) ]
      end
  end
end
