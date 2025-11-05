module Netsuite
  class Opportunity

    def self.create(args={})
      @client = Netsuite::Client.new(args)
      @client.create_opportunity
    end

    def self.create_opportunity
      @access_token = Netsuite::Base.get_access_token
      body_json = {
        "title": "New Opportunity - Test",
        "memo": "Test opportunity created via API",
        "tranDate": "2025-01-27",
        "expectedCloseDate": "2025-02-27",
        "probability": 50.0,
        "status": "In Progress",
        "entity": { "id": "10004", "type": "customer" },
        "currency": { "id": "1", "type": "currency", "refName": "AUD" },
        "subsidiary": { "id": "7", "type": "subsidiary" },
        "salesRep": { "id": "95066", "type": "contact" },
        "forecastType": { "id": "2", "type": "forecastType" },
        "exchangeRate": 1.0,
        "isBudgetApproved": false,
        "canHaveStackable": false,
        "shipIsResidential": false,
        "shipOverride": false,
        "altSalesTotal": 0,
        "altSalesRangeHigh": 0.0,
        "altSalesRangeLow": 0.0,
        "rangeHigh": 0.0,
        "rangeLow": 0.0,
        "weightedTotal": 0.0,
        "projAltSalesAmt": 0.0,
        "totalCostEstimate": 0.0,
        "estGrossProfit": 0.0,
        "projectedTotal": 0.0,
        "total": 0,
        "custbody14": { "id": "120", "type": "customList" }  # Use internal ID
      }

      response = HTTParty.post(
        "https://#{ENV['NETSUITE_ACCOUNT_ID']}.suitetalk.api.netsuite.com/services/rest/record/v1/opportunity",
        body: body_json.to_json,
        headers: {
          'Authorization' => "Bearer #{@access_token}",
          'Content-Type' => 'application/json'
        }
      )


      campaign_response = HTTParty.get(
        "https://#{ENV['NETSUITE_ACCOUNT_ID']}.suitetalk.api.netsuite.com/services/rest/record/v1/opportunity/3512345",
        headers: {
          'Authorization' => "Bearer #{@access_token}",
          'Content-Type' => 'application/json',
          'Accept' => 'application/json'
        }
      )

      response
    end
   
  end
end
