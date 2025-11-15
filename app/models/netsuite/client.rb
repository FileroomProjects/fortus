module Netsuite
  class Client
    attr_accessor :body, :access_token

    def initialize(args)
      @access_token = Netsuite::Base.get_access_token
      @body = args
    end

    def create_opportunity
      response = HTTParty.post(
        "https://#{ENV['NETSUITE_ACCOUNT_ID']}.suitetalk.api.netsuite.com/services/rest/record/v1/opportunity",
        body: body.to_json,
        headers: {
          "Authorization" => "Bearer #{access_token}",
          "Content-Type" => "application/json"
        }
      )

      if response.code == 204
        ns_opportunity_id = response.headers[:location].split("/").last if response.headers[:location].present?
        puts "Netsuite opportunity has been created id: #{ns_opportunity_id}"
        { id: ns_opportunity_id }
      else
        raise "Netsuite Client opportunity error :" + "#{response.parsed_response}"
      end
    end

    def create_contact
      response = HTTParty.post(
        "https://#{ENV['NETSUITE_ACCOUNT_ID']}.suitetalk.api.netsuite.com/services/rest/record/v1/contact",
        body: body.to_json,
        headers: {
          "Authorization" => "Bearer #{access_token}",
          "Content-Type" => "application/json"
        }
      )

      if response.code == 204
        ns_contact_id = response.headers[:location].split("/").last
        { id: ns_contact_id }
      else
        raise "Netsuite Client Contact error :"  + "#{response["errors"].collect { |a| a["message"] }.join(',')}"
      end
    end

    def search_contact_by_id
      query_str = body.map { |k, v| "#{k} EQUAL \"#{v}\"" }.join(" AND ")

      response = HTTParty.get(
        "https://#{ENV['NETSUITE_ACCOUNT_ID']}.suitetalk.api.netsuite.com/services/rest/record/v1/contact",
        query: { q: query_str, limit: 1, offset: 0 },
        headers: {
          "Authorization" => "Bearer #{access_token}",
          "Content-Type" => "application/json"
        }
      )

      if response.code == 200
        response.parsed_response
      else
        raise "Netsuite Client Contact error :" + "#{response["errors"].collect { |a| a["message"] }.join(',')}"
      end
    end

    def search_contact_by_properties
      query_str = body.map { |k, v| "#{k} IS \"#{v}\"" }.join(" AND ")

      response = HTTParty.get(
        "https://#{ENV['NETSUITE_ACCOUNT_ID']}.suitetalk.api.netsuite.com/services/rest/record/v1/contact",
        query: { q: query_str, limit: 1, offset: 0 },
        headers: {
          "Authorization" => "Bearer #{access_token}",
          "Content-Type" => "application/json"
        }
      )

      if response.code == 200
        JSON.parse(response.parsed_response)["items"].first
      else
        raise "Netsuite Client Contact error :" + "#{response["errors"].collect { |a| a["message"] }.join(',')}"
      end
    end

    def search_customer_by_properties
      query_str = body.map { |k, v| "#{k} IS \"#{v}\"" }.join(" AND ")

      response = HTTParty.get(
        "https://#{ENV['NETSUITE_ACCOUNT_ID']}.suitetalk.api.netsuite.com/services/rest/record/v1/customer",
        query: { q: query_str, limit: 1, offset: 0 },
        headers: {
          "Authorization" => "Bearer #{access_token}",
          "Content-Type" => "application/json"
        }
      )
      if response.code == 200
        JSON.parse(response.parsed_response)["items"].first
      else
        raise "Netsuite Client Contact error :" + "#{response["errors"].collect { |a| a["message"] }.join(',')}"
      end
    end

    def create_quote
      response = HTTParty.post(
        "https://#{ENV['NETSUITE_ACCOUNT_ID']}.suitetalk.api.netsuite.com/services/rest/record/v1/estimate",
        body: body.to_json,
        headers: {
          "Authorization" => "Bearer #{access_token}",
          "Content-Type" => "application/json"
        }
      )
      byebug
      if response.code == 204
        ns_contact_id = response.headers[:location].split("/").last
        { id: ns_contact_id }
      else
        raise "Netsuite Client Contact error :"  + "#{response["errors"].collect { |a| a["message"] }.join(',')}"
      end
    end
  end
end
