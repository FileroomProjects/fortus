module Hubspot
  class Client
    attr_accessor :body

    def initialize(args)
      @body = args[:body]
    end

    def fetch_deal
      response = HTTParty.get(
        "https://api.hubapi.com/deals/v1/deal/#{body[:deal_id]}",
        headers: {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{ENV['HUBSPOT_ACCESS_TOKEN']}"
        }
      )

      if response["errors"] && response["errors"].any?
        raise response["errors"].collect { |a| a["message"] }.join(",")
      end
      response.parsed_response["results"]&.first
    end

    def fetch_campaign_by_deal
      response = HTTParty.get(
        "https://api.hubapi.com/crm/v4/objects/deals/#{body[:deal_id]}/associations/campaign",
        headers: { "Authorization" => "Bearer #{ENV['HUBSPOT_ACCESS_TOKEN']}" }
      )
    end

    def fetch_company
      response = HTTParty.post(
        "https://api.hubapi.com/crm/v3/associations/deal/company/batch/read",
        body: body.to_json,
        headers: {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{ENV['HUBSPOT_ACCESS_TOKEN']}"
        }
      )
      if response["errors"] && response["errors"].any?
        raise response["errors"].collect { |a| a["message"] }.join(",")
      end
      response["results"]
    end

    def fetch_contact_by_deal
      response = HTTParty.get(
        "https://api.hubapi.com/crm/v4/objects/deals/#{body[:deal_id]}/associations/contacts",
        headers: {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{ENV['HUBSPOT_ACCESS_TOKEN']}"
        }
      )

      if response["errors"] && response["errors"].any?
        raise response["errors"].collect { |a| a["message"] }.join(",")
      end
      response.parsed_response["results"]&.first
    end

    def fetch_company_by_deal
      response = HTTParty.get(
        "https://api.hubapi.com/crm/v4/objects/deals/#{body[:deal_id]}/associations/companies",
        headers: {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{ENV['HUBSPOT_ACCESS_TOKEN']}"
        }
      )

      if response["errors"] && response["errors"].any?
        raise response["errors"].collect { |a| a["message"] }.join(",")
      end
      response.parsed_response["results"]&.first
    end

    def fetch_contact_by_id
      response = HTTParty.get(
        "https://api.hubapi.com/contacts/v1/contact/vid/#{body[:id]}/profile",
        headers: {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{ENV['HUBSPOT_ACCESS_TOKEN']}"
        }
      )
      if response["errors"] && response["errors"].any?
        raise response["errors"].collect { |a| a["message"] }.join(",")
      end
      response.parsed_response["properties"]
    end

    def fetch_company_by_id
      response = HTTParty.get(
        "https://api.hubapi.com/companies/v2/companies/#{body[:id]}",
        headers: {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{ENV['HUBSPOT_ACCESS_TOKEN']}"
        }
      )
      if response["errors"] && response["errors"].any?
        raise response["errors"].collect { |a| a["message"] }.join(",")
      end
      response.parsed_response["properties"]
    end

    def update_contact
      contact_id = body.delete(:contactId)
      response = HTTParty.patch(
        "https://api.hubapi.com/crm/v3/objects/contacts/#{contact_id}",
        body: { 'properties': body }.to_json,
        headers: {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{ENV['HUBSPOT_ACCESS_TOKEN']}"
        }
      )
      if response.code == 200
        response.parsed_response
      else
        raise response.parsed_response.collect { |a| a["message"] }.join(",")
      end
    end

    def update_deal
      deal_id = body.delete(:deal_id)
      response = HTTParty.patch(
        "https://api.hubapi.com/crm/v3/objects/deals/#{deal_id}",
        body: { 'properties': body }.to_json,
        headers: {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{ENV['HUBSPOT_ACCESS_TOKEN']}"
        }
      )

      if response.code == 200
        response.parsed_response
      else
        raise response.parsed_response.collect { |a| a["message"] }.join(",")
      end
    end

    def update_company
      company_id = body.delete(:companyId)
      response = HTTParty.patch(
        "https://api.hubapi.com/crm/v3/objects/companies/#{company_id}",
        body: { 'properties': body }.to_json,
        headers: {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{ENV['HUBSPOT_ACCESS_TOKEN']}"
        }
      )

      if response.code == 200
        return response.parsed_response
      end
      raise response.parsed_response.collect { |a| a["message"] }.join(",")
    end
  end
end
