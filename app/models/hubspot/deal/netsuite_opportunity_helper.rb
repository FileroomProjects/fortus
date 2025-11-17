module Hubspot::Deal::NetsuiteOpportunityHelper
  extend ActiveSupport::Concern

  included do
    QUOTES_STAGES = [
      { label: "Open", id: "1979552193" },
      { label: "Closed Won", id: "1979552198" },
      { label: "Closed Lost", id: "1979552199" }
    ].freeze

    def get_stage_from_quotes_pl(stage_code)
      Hubspot::Deal::QUOTES_STAGES.select { |a| a[:id] == stage_code }.first[:label]
    end

    def prepare_payload_for_netsuite_opportunity
      {
        "title": fetch_prop_field(:dealname),
        "memo": "Test opportunity created via API new",
        "tranDate": Time.at(fetch_prop_field(:createdate).to_i / 1000).utc.strftime("%Y-%m-%d"),
        "expectedCloseDate": Time.at(fetch_prop_field(:closedate).to_i / 1000).utc.strftime("%Y-%m-%d"),
        "status": get_stage_from_quotes_pl(fetch_prop_field(:dealstage)),
        "probability": fetch_prop_field(:hs_deal_stage_probability).to_f,
        "entity": { "id": netsuite_company_id, "type": "customer" },
        "contact": { "id": netsuite_contact_id, "type": "contact" },
        "currency": { "id": "2", "type": "currency", "refName": fetch_prop_field(:deal_currency_code) },
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
  end
end
