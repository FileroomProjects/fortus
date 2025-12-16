module Netsuite
  class Client
    attr_accessor :body, :access_token

    include HttpsRequest

    BASE_URL = "https://#{ENV['NETSUITE_ACCOUNT_ID']}.suitetalk.api.netsuite.com/services/rest/record/v1"
    SUITEQL_URL = "https://#{ENV['NETSUITE_ACCOUNT_ID']}.suitetalk.api.netsuite.com/services/rest/query/v1/suiteql"

    def initialize(args)
      @access_token = Netsuite::Base.get_access_token
      @body = args
    end

    def search_contact_by_id
      query_str = build_query("EQUAL")
      search_contact(query_str)
    end

    def search_contact_by_properties
      query_str = build_query("IS")
      search_contact(query_str)
    end

    def search_customer_by_properties
      query_str = "SELECT * FROM customer WHERE LOWER(#{body[:columnName]}) = LOWER('#{body[:value]}')"
      url = "#{SUITEQL_URL}?limit=1&offset=0"
      search_customer(url, query_str)
    end

    def fetch_object(name, id)
      response = get_request("#{BASE_URL}/#{name}/#{id}", headers)

      handle_error(name, response) unless response.code == 200

      JSON.parse(response.parsed_response)
    end

    def create_object(object_name)
      response = post_request("#{BASE_URL}/#{object_name}", body, headers)

      handle_error(object_name, response) unless response.code == 204

      object_id = response.headers[:location].split("/").last if response.headers[:location].present?
      { id: object_id }
    end

    def update_object(object_name, object_id)
      response = patch_request("#{BASE_URL}/#{object_name}/#{object_id}", body, headers)

      handle_error(object_name, response) unless response.code == 204

      object_id = response.headers[:location].split("/").last if response.headers[:location].present?
      { id: object_id }
    end

    def fetch_estimate_items(estimate_id)
      response = get_request("#{BASE_URL}/estimate/#{estimate_id}?expandSubResources=true", headers)

      handle_error("estimate", response) unless response.code == 200

      JSON.parse(response.parsed_response)
    end

    def fetch_locations
      query_str = "SELECT id, subsidiary FROM location WHERE isinactive = 'F'"
      response = post_request(SUITEQL_URL, { q: query_str }, headers_with_prefer)

      handle_error("location", response) unless response.code == 200

      JSON.parse(response.parsed_response)
    end

    private
      def search_contact(query_str)
        response = search_query("#{BASE_URL}/contact", { q: query_str, limit: 1, offset: 0 }, headers)

        handle_error("contact", response) unless response.code == 200

        JSON.parse(response.parsed_response)["items"].first
      end

      def search_customer(url, query_str)
        response = post_request(url, { q: query_str }, headers_with_prefer)

        handle_error("customer", response) unless response.code == 200

        JSON.parse(response.parsed_response)["items"].first
      end

      def headers
        {
          "Authorization" => "Bearer #{access_token}",
          "Content-Type" => "application/json"
        }
      end

      def headers_with_prefer
        headers.merge({ "Prefer" => "transient" })
      end

      def build_query(operator)
        body.map { |k, v| "#{k} #{operator} \"#{v}\"" }.join(" AND ")
      end

      def handle_error(object_name, response)
        raise "Netsuite Client #{object_name} error : #{JSON.parse(response)["o:errorDetails"].map { |e| e["detail"] }.join(", ")}"
      end
  end
end
