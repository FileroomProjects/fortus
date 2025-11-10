module Hubspot
  class Deal < Hubspot::Base
    STAGES = [
      { label: "Open", id: "1979552193" },
      { label: "Closed Won", id: "1979552198" },
      { label: "Closed Lost", id: "1979552199" }
    ].freeze
    
    def associated_company
      Hubspot::Company::find_by_deal_id(args[:objectId])
    end

    def associated_contact
      Hubspot::Contact::find_by_deal_id(args[:objectId])
    end

    def associated_contact_details
      contact_id = Hubspot::Contact::find_by_deal_id(args[:objectId])[:toObjectId]
      raise "Contact is not present" if contact_id.blank?
      
      Hubspot::Contact::find_by_id(contact_id)
    end

    def self.find_by(args)
      @client = Hubspot::Client.new(body: args)

      @client.fetch_deal
    end

    def sync_with_netsuite
      @payload = prepare_payload_for_netsuite
      Netsuite::Opportunity.create(@payload)
      handle_contact_and_update_hubspot
    end

    def fetch_prop_field(field_name)
      f_value = (properties[field_name.to_sym] || properties[field_name.to_s])[:versions]&.first
      f_value[:value] if f_value.present?
    end

    def get_stage(stage_code)
      Hubspot::Deal::STAGES.select{|a| a[:id] == stage_code }.first[:label]
    end

    def prepare_payload_for_netsuite
      {
        "title": fetch_prop_field(:dealname),
        "memo": "Test opportunity created via API new",
        "tranDate": Time.at(fetch_prop_field(:createdate).to_i / 1000).utc.strftime("%Y-%m-%d"),
        "expectedCloseDate": Time.at(fetch_prop_field(:closedate).to_i / 1000).utc.strftime("%Y-%m-%d"),
        "probability": fetch_prop_field(:hs_deal_stage_probability).to_f,
        "entity": { "id": "10004", "type": "customer" },
        "currency": { "id": "1", "type": "currency", "refName": fetch_prop_field(:deal_currency_code) },
        "subsidiary": { "id": "7", "type": "subsidiary" },
        # "salesRep": { "id": fetch_prop_field(:hubspot_owner_id).to_i, "type": "contact" },
        "forecastType": { "id": "2", "type": "forecastType" },
        "exchangeRate": 1.0,
        "isBudgetApproved": false,
        "canHaveStackable": false,
        "shipIsResidential": false,
        "shipOverride": false,
        "rangeHigh": 0.0,
        "rangeLow": 0.0,
        "weightedTotal": 0.0,
        "totalCostEstimate": 0.0,
        "estGrossProfit": 0.0,
        "projectedTotal": fetch_prop_field(:hs_projected_amount).to_f,
        "total": fetch_prop_field(:hs_projected_amount).to_f,
        "custbody14": { "id": "120", "type": "customList" }  # Use internal ID
      }
    end

    def handle_contact_and_update_hubspot
      contact_details = associated_contact_details
      if contact_details.present?
        if contact_details[:netsuite_contact_id].present?
          Rails.logger.info "************ netsuite_contact_id is present"
        else
          ns_contact = Netsuite::Contact.create(
            "firstName": contact_details[:firstname]&.fetch("value", ''),
            "lastName": "Doe",
            "email": contact_details[:email]&.fetch("value", ''),
            "jobTitle": contact_details[:jobtitle]&.fetch("value", ''),
            "isInactive": false,
            company: { "id": 123, "type": "customer" }
          )
          netsuite_contact_id = ns_contact[:id]
          
          if ns_contact && netsuite_contact_id.present?
            Hubspot::Contact.update({
              contactId: contact_details[:hs_object_id][:value], 
              "netsuite_contact_id": netsuite_contact_id
            })
          end
        end
      else
        Rails.logger.log('************ Contact detail is blank')
      end
    end

    def handle_company_and_update_hubspot
      contact_details = associated_contact_details
      if contact_details.present?
        if contact_details[:netsuite_contact_id].present?
          netsuite_contact_id = contact_details[:netsuite_contact_id]
          Rails.logger.info "************ netsuite_contact_id is present"
        else
          ns_contact = Netsuite::Contact.create(
            "firstName": contact_details[:firstname]&.fetch("value", ''),
            "lastName": "Doe",
            "email": contact_details[:email]&.fetch("value", ''),
            "jobTitle": contact_details[:jobtitle]&.fetch("value", ''),
            "isInactive": false,
            company: { "id": 123, "type": "customer" }
          )
          netsuite_contact_id = ns_contact[:id]
        end
        if netsuite_contact_id.present?
          Hubspot::Contact.update({
            contactId: contact_details[:hs_object_id][:value], 
            "netsuite_contact_id": netsuite_contact_id
          })
        end
      else
        Rails.logger.log('************ Contact detail is blank')
      end
    end
  end
end
