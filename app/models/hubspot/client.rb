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
        raise response["errors"].collect{|a| a["message"]}.join(',')
      end
      return response.parsed_response["results"]&.first
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
        raise response["errors"].collect{|a| a["message"]}.join(',')
      end
      return response["results"]
    end

    def fetch_contact
      response = HTTParty.get(
        "https://api.hubapi.com/crm/v4/objects/deals/#{body[:deal_id]}/associations/contacts",
        headers: {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{ENV['HUBSPOT_ACCESS_TOKEN']}"
        }
      )

      if response["errors"] && response["errors"].any?
        raise response["errors"].collect{|a| a["message"]}.join(',')
      end
      return response.parsed_response["results"]&.first
    end

    def call
    end
  end
end
