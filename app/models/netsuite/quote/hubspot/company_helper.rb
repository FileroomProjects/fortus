module Netsuite::Quote::Hubspot::CompanyHelper
  extend ActiveSupport::Concern

  include Netsuite::Hubspot::CompanyHelper

  included do
    def update_company_info
      hs_company = find_company(filters)
      payload = payload_to_update_hubspot_company(hs_company[:id])
      update_company(payload)
    end

    private
      def filters
        [
          build_search_filter("netsuite_company_id", "EQ", args[:customer][:id])
        ]
      end

      def payload_to_update_hubspot_company(hs_company_id)
        {
          companyId: hs_company_id,
          "name": args[:customer][:companyName]
        }
      end
  end
end
