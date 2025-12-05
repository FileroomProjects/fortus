module Netsuite::Quote::Hubspot::CompanyHelper
  extend ActiveSupport::Concern

  include Netsuite::Hubspot::CompanyHelper

  included do
    def update_or_create_hubspot_company
      return nil unless args[:customer][:id].present?

      hs_company = find_company(company_filters, raise_error: false)
      if object_present_with_id?(hs_company)
        update_hubspot_company(hs_company)
      else
        create_hubspot_company
      end
    end

    def update_hubspot_company(hs_company)
      payload = payload_to_update_hubspot_company(hs_company[:id])
      update_company(payload)
    end

    def create_hubspot_company
      payload = payload_to_create_hubspot_company
      create_company(payload)
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

      def payload_to_create_hubspot_company
        {
          "properties": {
            "name": args[:customer][:name],
            "netsuite_company_id": args[:customer][:id]
          }
        }
      end
  end
end
