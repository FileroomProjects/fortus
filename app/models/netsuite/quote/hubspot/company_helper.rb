module Netsuite::Quote::Hubspot::CompanyHelper
  extend ActiveSupport::Concern

  include Netsuite::Hubspot::CompanyHelper

  included do
    def find_hubspot_company
      find_company(company_filters)
    end

    def update_company_info
      payload = payload_to_update_hubspot_company(@hs_company[:id])
      update_company(payload)
    end

    private
      def company_filters
        [
          build_search_filter("netsuite_company_id", "EQ", args[:customer][:id])
        ]
      end

      def payload_to_update_hubspot_company(hs_company_id)
        {
          companyId: hs_company_id,
          "name": args[:customer][:name]
        }
      end
  end
end
