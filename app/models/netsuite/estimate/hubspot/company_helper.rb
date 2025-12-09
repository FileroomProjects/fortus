module Netsuite::Estimate::Hubspot::CompanyHelper
  extend ActiveSupport::Concern

  included do
    # Ensure a HubSpot company exists for the NetSuite customer.
    # - Returns the updated or newly created HubSpot company object, or nil when no customer id is present.
    def update_or_create_hubspot_company
      return nil unless args[:customer][:id].present?

      hs_company = find_hubspot_company
      if object_present_with_id?(hs_company)
        update_hubspot_company(hs_company)
      else
        create_hubspot_company
      end
    end

    # Find a HubSpot company for the current NetSuite customer.
    # Searches by NetSuite company id first, then by company name; returns the first match or nil.
    def find_hubspot_company
      [
        [ :id,   :build_company_filter_with_id ],
        [ :name, :build_company_filter_with_name ]
      ].each do |key, builder|
        next unless args[:customer][key].present?
        hs_company = find_hs_company(send(builder), raise_error: false)
        return hs_company if object_present_with_id?(hs_company)
      end

      nil
    end

    def update_hubspot_company(hs_company)
      payload = payload_to_update_hubspot_company(hs_company[:id])
      update_hs_company(payload)
    end

    def create_hubspot_company
      payload = payload_to_create_hubspot_company
      create_hs_company(payload)
    end

    private
      def build_company_filter_with_id
        [
          build_search_filter("netsuite_company_id", "EQ", args[:customer][:id])
        ]
      end

      def build_company_filter_with_name
        [
          build_search_filter("name", "EQ", args[:customer][:name])
        ]
      end

      def payload_to_update_hubspot_company(hs_company_id)
        {
          companyId: hs_company_id,
          "name": args[:customer][:name],
          "netsuite_company_id": args[:customer][:id]
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
