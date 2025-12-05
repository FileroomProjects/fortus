module IntegrationCommon
  extend ActiveSupport::Concern

  included do
    def build_search_payload(filters)
      {
        filterGroups: [
          {
            filters: filters
          }
        ]
      }
    end

    def build_search_filter(property_name, operator, value, multiple: false)
      {
        propertyName: property_name,
        operator: operator
      }.merge(multiple ? { values: value } : { value: value })
    end

    def payload_to_associate(from_id, to_id, type)
      {
        "inputs": [
          {
            "from": { "id": from_id },
            "to": { "id": to_id },
            "type": type
          }
        ]
      }
    end

    def association(target_id, type_id)
      {
        to: { id: target_id },
        types: [
          {
            associationCategory: "HUBSPOT_DEFINED",
            associationTypeId: type_id
          }
        ]
      }
    end

    def object_present_with_id?(object)
      object.present? && object[:id].present?
    end

    def netsuite_estimate_location(ns_quote_id)
      "https://#{ENV['NETSUITE_ACCOUNT_ID']}.app.netsuite.com/app/accounting/transactions/estimate.nl?id=#{ns_quote_id}&whence="
    end
  end
end
