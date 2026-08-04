module Hubspot::Deal::NetsuiteOpportunityHelper
  extend ActiveSupport::Concern

  included do
    ESTIMATE_STAGES = [
      { label: "Open", id: "1979552193" },
      { label: "Closed Won", id: "1979552198" },
      { label: "Closed Lost", id: "1979552199" }
    ].freeze

    def find_or_create_netsuite_opportunity
      if @netsuite_opportunity_id.blank?
        create_netsuite_opportunity_and_update_hubspot_deal
        return
      end

      ns_opportunity = find_ns_opportunity_with_id(@netsuite_opportunity_id)

      return  update_netsuite_opportunity(ns_opportunity) if object_present_with_id?(ns_opportunity)

      create_netsuite_opportunity_and_update_hubspot_deal
    end

    def create_netsuite_opportunity_and_update_hubspot_deal
      payload = prepare_payload_for_netsuite_opportunity
      ns_opportunity = create_ns_oppportunity(payload, deal_id)
      Rails.logger.info "[INFO] [SYNC.HUBSPOT_TO_NETSUITE.DEAL] [CREATE] [deal_id: #{deal_id}, opportunity_id: #{ns_opportunity[:id]}] Netsuite opportunity created successfully"

      @netsuite_opportunity_id = ns_opportunity[:id]

      update_hs_deal({ deal_id: deal_id, "netsuite_opportunity_id": ns_opportunity[:id] })

      Rails.logger.info "[INFO] [SYNC.HUBSPOT_TO_NETSUITE.DEAL] [UPDATE] [deal_id: #{deal_id}, opportunity_id: #{ns_opportunity[:id]}] HubSpot deal updated successfully"
      Rails.logger.info "[INFO] [SYNC.HUBSPOT_TO_NETSUITE.DEAL] [COMPLETE] [deal_id: #{deal_id}, opportunity_id: #{ns_opportunity[:id]}] Opportunity synchronized successfully"

      ns_opportunity
    end

    def update_netsuite_opportunity(ns_opportunity)
      payload = prepare_payload_for_netsuite_opportunity_update
      ns_opportunity = update_ns_opportunity(payload, ns_opportunity[:id], deal_id)

      Rails.logger.info "[INFO] [SYNC.HUBSPOT_TO_NETSUITE.DEAL] [UPDATE] [deal_id: #{deal_id}, opportunity_id: #{ns_opportunity[:id]}] Netsuite opportunity updated successfully"
      Rails.logger.info "[INFO] [SYNC.HUBSPOT_TO_NETSUITE.DEAL] [COMPLETE] [deal_id: #{deal_id}, opportunity_id: #{ns_opportunity[:id]}] Opportunity synchronized successfully"

      ns_opportunity
    end

    private
      def get_stage_from_pl(stage_code)
        Hubspot::Deal::ESTIMATE_STAGES.select { |a| a[:id] == stage_code }.first[:label]
      end

      def prepare_payload_for_netsuite_opportunity
        payload = {
          "title": fetch_prop_field(:dealname),
          "custbody61": fetch_prop_field(:request_quote_notes),
          "custbodyhubspot_opportunity_quote_note": request_quote_triggered?,
          "memo": "Test opportunity created via API new",
          "tranDate": format_timestamp(fetch_prop_field(:createdate)),
          "expectedCloseDate": format_timestamp(fetch_prop_field(:closedate)),
          "status": "Open",
          "probability": fetch_prop_field(:hs_deal_stage_probability).to_f * 100, # Probability must be equal to or greater than 1.
          "entity": { "id": netsuite_company_id, "type": "customer" },
          "contact": { "id": netsuite_contact_id, "type": "contact" },
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
          "custbody14": { "id": "120", "type": "customList" },
          "custbody61": fetch_prop_field(:request_quote_notes) # Use internal ID
        }
        sales_rep = netsuite_sales_rep
        payload["salesRep"] = sales_rep if sales_rep.present?
        payload
      end

      def format_timestamp(ms_timestamp)
        Time.at(ms_timestamp.to_i / 1000).utc.strftime("%Y-%m-%d")
      end

      def request_quote_triggered?
        fetch_prop_field(:request_quote_triggered) == "true"
      end

      def prepare_payload_for_netsuite_opportunity_update
        payload = {
          "custbody61": fetch_prop_field(:request_quote_notes)
        }
        sales_rep = netsuite_sales_rep
        payload["salesRep"] = sales_rep if sales_rep.present?
        payload
      end

      def netsuite_sales_rep
        employee_id = netsuite_employee_id_for_deal_owner
        return if employee_id.blank?

        { "id" => employee_id }
      end

      def netsuite_employee_id_for_deal_owner
        owner_id = fetch_prop_field(:hubspot_owner_id)
        return if owner_id.blank?

        owner_email = hubspot_owner_email(owner_id)
        return if owner_email.blank?

        find_netsuite_employee_id_by_email(owner_email)
      end

      def hubspot_owner_email(owner_id)
        response = HTTParty.get(
          "https://api.hubapi.com/crm/v3/owners/#{owner_id}",
          headers: {
            "Authorization" => "Bearer #{ENV['HUBSPOT_ACCESS_TOKEN']}",
            "Content-Type" => "application/json"
          }
        )
        return unless response.code == 200

        JSON.parse(response.body)["email"]
      rescue => e
        Rails.logger.error "[ERROR] [SYNC.HUBSPOT_TO_NETSUITE.DEAL] [OWNER] [deal_id: #{deal_id}, owner_id: #{owner_id}] Failed to fetch HubSpot owner: #{e.message}"
        nil
      end

      def find_netsuite_employee_id_by_email(email)
        response = HTTParty.get(
          "https://#{ENV['NETSUITE_ACCOUNT_ID']}.suitetalk.api.netsuite.com/services/rest/record/v1/employee",
          query: { q: "email IS \"#{email}\"" },
          headers: {
            "Authorization" => "Bearer #{Netsuite::Base.get_access_token}",
            "Content-Type" => "application/json"
          }
        )
        return unless response.code == 200

        JSON.parse(response.body)["items"]&.first&.dig("id")
      rescue => e
        Rails.logger.error "[ERROR] [SYNC.HUBSPOT_TO_NETSUITE.DEAL] [EMPLOYEE] [deal_id: #{deal_id}, email: #{email}] Failed to find NetSuite employee: #{e.message}"
        nil
      end
  end
end
