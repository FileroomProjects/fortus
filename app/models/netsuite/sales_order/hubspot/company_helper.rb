module Netsuite::SalesOrder::Hubspot::CompanyHelper
  extend ActiveSupport::Concern

  included do
    def find_hubspot_company
      hs_company = Hubspot::Company.search(payload_for_search_hubspot_company)
      if hs_company.present? && hs_company[:id].present?
        Rails.logger.info "************** Hubspot Company found with ID #{hs_company[:id]}"
        hs_company
      else
        raise "Hubspot Company not found"
      end
    end

    private
      def payload_for_search_hubspot_company
        {
          filterGroups: [
            {
              filters: [
                {
                  propertyName: "netsuite_company_id",
                  operator: "EQ",
                  value: args[:customer][:id]
                }
              ]
            }
          ]
        }
      end
  end
end
