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
        ns_opportunity = create_netsuite_opportunity_and_update_hubspot_deal
        return ns_opportunity
      end

      ns_opportunity = find_ns_opportunity_with_id(@netsuite_opportunity_id)

      create_netsuite_opportunity_and_update_hubspot_deal unless object_present_with_id?(ns_opportunity)
    end

    def create_netsuite_opportunity_and_update_hubspot_deal
      payload = prepare_payload_for_netsuite_opportunity
      ns_opportunity = create_ns_oppportunity(payload)

      @netsuite_opportunity_id = ns_opportunity[:id]

      info_log("Updating Hubspot deal with netsuite_opportunity_id #{ns_opportunity[:id]}")
      update({ "netsuite_opportunity_id": ns_opportunity[:id] })
      ns_opportunity
    end

    private
      def get_stage_from_pl(stage_code)
        Hubspot::Deal::ESTIMATE_STAGES.select { |a| a[:id] == stage_code }.first[:label]
      end

      def prepare_payload_for_netsuite_opportunity
        {
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
          "currency": { "id": "2", "type": "currency" },
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

      def format_timestamp(ms_timestamp)
        Time.at(ms_timestamp.to_i / 1000).utc.strftime("%Y-%m-%d")
      end

      def request_quote_triggered?
        fetch_prop_field(:request_quote_triggered) == "true"
      end
  end
end
