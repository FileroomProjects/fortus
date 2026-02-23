module BaseConcern
  extend ActiveSupport::Concern

  include HubspotCompany
  include HubspotContact
  include HubspotDeal
  include HubspotLineItem
  include HubspotOrder
  include NetsuiteContact
  include NetsuiteCustomer
  include NetsuiteEstimate
  include NetsuiteOpportunity

  included do
    # Build a HubSpot search payload from an array of filters.
    # Returns a Hash usable by HubSpot search endpoints.
    def build_search_payload(filters)
      { filterGroups: [ { filters: filters } ] }
    end

    # Build a single HubSpot search filter.
    # - property_name: HubSpot property name to filter on
    # - operator: Operator string (eg. "EQ", "IN")
    # - value: value or array of values
    # - multiple: when true, use `values` (array) instead of `value`.
    def build_search_filter(property_name, operator, value, multiple: false)
      {
        propertyName: property_name,
        operator: operator
      }.merge(multiple ? { values: value } : { value: value })
    end

    # Build an association payload for HubSpot `associations` API.
    # - from_id: source object ID
    # - to_id: target object ID
    # - type: association type string
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

    # Build the association hash used when embedding association info.
    # - target_id: ID of the associated object
    # - type_id: numeric HubSpot association type id
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

    # Helper to check presence and that object contains an :id key.
    def object_present_with_id?(object)
      object.present? && object[:id].present?
    end

    # Build a NetSuite UI URL for the given estimate id.
    def netsuite_estimate_location(ns_estimate_id)
      "https://#{ENV['NETSUITE_ACCOUNT_ID']}.app.netsuite.com/app/accounting/transactions/estimate.nl?id=#{ns_estimate_id}&whence="
    end

    def process_response(object_name, action, object)
      success = object_present_with_id?(object)

      unless success
        raise "#{object_name} not #{action}"
      end
      object
    end
  end
end
