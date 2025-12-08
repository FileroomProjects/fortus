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
    def build_search_payload(filters)
      { filterGroups: [ { filters: filters } ] }
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

    def netsuite_estimate_location(ns_estimate_id)
      "https://#{ENV['NETSUITE_ACCOUNT_ID']}.app.netsuite.com/app/accounting/transactions/estimate.nl?id=#{ns_estimate_id}&whence="
    end

    def process_response(object_name, action, object, raise_error = true)
      success = object_present_with_id?(object)

      log_message(object_name, action, object, success)

      raise "Failed to #{action} #{object_name}" if !success && raise_error
      return nil unless success

      object
    end

    def log_message(object_name, action, object, success)
      if success
        info_log("#{action} #{object_name} with ID #{object[:id]}")
      else
        info_log("#{object_name} not #{action}")
      end
    end

    def info_log(log_message)
      Rails.logger.info "************** #{log_message}"
    end
  end
end
