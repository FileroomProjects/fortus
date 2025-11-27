module Netsuite
  class Client
    attr_accessor :body, :access_token

    def initialize(args)
      @access_token = Netsuite::Base.get_access_token
      @body = args
    end

    def create_opportunity
      response = HTTParty.post(
        "#{Netsuite::Base::BASE_URL}/opportunity",
        body: body.to_json,
        headers: {
          "Authorization" => "Bearer #{access_token}",
          "Content-Type" => "application/json"
        }
      )

      if response.code == 204
        ns_opportunity_id = response.headers[:location].split("/").last if response.headers[:location].present?
        Rails.logger.info "****************** Netsuite opportunity has been created id: #{ns_opportunity_id}"
        { id: ns_opportunity_id }
      else
        raise "Netsuite Client opportunity error : #{JSON.parse(response)["o:errorDetails"].map { |e| e["detail"] }.join(", ")}"
      end
    end

    def create_contact
      response = HTTParty.post(
        "#{Netsuite::Base::BASE_URL}/contact",
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
        raise "Netsuite Client Contact error: #{JSON.parse(response)["o:errorDetails"].map { |e| e["detail"] }.join(", ")}"
      end
    end

    def create_customer
      response = HTTParty.post(
        "#{Netsuite::Base::BASE_URL}/customer",
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
        raise "Netsuite Client Customer error : #{JSON.parse(response)["o:errorDetails"].map { |e| e["detail"] }.join(", ")}"
      end
    end

    def search_contact_by_id
      query_str = body.map { |k, v| "#{k} EQUAL \"#{v}\"" }.join(" AND ")

      response = HTTParty.get(
        "#{Netsuite::Base::BASE_URL}/contact",
        query: { q: query_str, limit: 1, offset: 0 },
        headers: {
          "Authorization" => "Bearer #{access_token}",
          "Content-Type" => "application/json"
        }
      )

      if response.code == 200
        JSON.parse(response.parsed_response)["items"].first
      else
        raise "Netsuite Client Contact error : #{JSON.parse(response)["o:errorDetails"].map { |e| e["detail"] }.join(", ")}"
      end
    end

    def search_contact_by_properties
      query_str = body.map { |k, v| "#{k} IS \"#{v}\"" }.join(" AND ")

      response = HTTParty.get(
        "#{Netsuite::Base::BASE_URL}/contact",
        query: { q: query_str, limit: 1, offset: 0 },
        headers: {
          "Authorization" => "Bearer #{access_token}",
          "Content-Type" => "application/json"
        }
      )

      if response.code == 200
        JSON.parse(response.parsed_response)["items"].first
      else
        raise "Netsuite Client Contact error : #{JSON.parse(response)["o:errorDetails"].map { |e| e["detail"] }.join(", ")}"
      end
    end

    def search_customer_by_properties
      query_str = "SELECT * FROM customer WHERE LOWER(#{body[:columnName]}) = LOWER('#{body[:value]}')"

      response = HTTParty.post(
        "https://#{ENV['NETSUITE_ACCOUNT_ID']}.suitetalk.api.netsuite.com/services/rest/query/v1/suiteql?limit=1&offset=0",
        body: { q: query_str }.to_json,
        headers: {
          "Authorization" => "Bearer #{access_token}",
          "Content-Type" => "application/json",
          "Prefer" => "transient"
        }
      )
      if response.code == 200
        JSON.parse(response.parsed_response)["items"].first
      else
        raise "Netsuite Client Customer error : #{JSON.parse(response)["o:errorDetails"].map { |e| e["detail"] }.join(", ")}"
      end
    end

    def create_quote
      response = HTTParty.post(
        "#{Netsuite::Base::BASE_URL}/estimate",
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
        raise "Netsuite Client Estimate error : #{JSON.parse(response)["o:errorDetails"].map { |e| e["detail"] }.join(", ")}"
      end
    end

    def fetch_object(object_name_and_id)
      response = HTTParty.get(
        "#{Netsuite::Base::BASE_URL}/#{object_name_and_id}",
        headers: {
          "Authorization" => "Bearer #{access_token}",
          "Content-Type" => "application/json"
        }
      )

      if response.code == 200
        JSON.parse(response.parsed_response)
      else
        raise "Netsuite Client Opportunity error : #{JSON.parse(response)["o:errorDetails"].map { |e| e["detail"] }.join(", ")}"
      end
    end
  end
end
