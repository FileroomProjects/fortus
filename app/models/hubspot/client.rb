module Hubspot
  class Client
    attr_accessor :body

    BASE_URL = "https://api.hubapi.com"

    def initialize(args)
      @body = args[:body]
    end

    def fetch_deal
      url = "/deals/v1/deal/#{body[:deal_id]}"
      response = get_request(url)

      if response.code == 200
        response.parsed_response["results"]&.first
      else
        raise response.parsed_response["message"]
      end
    end

    def fetch_company
      url = "/crm/v3/associations/deal/company/batch/read"
      response = post_request(url, body)

      if response.code == 200
        response.parsed_response["results"]
      elsif response.code == 207
        raise response.parsed_response["errors"].map { |e| e["message"] }.join(", ")
      else
        raise response.parsed_response["message"]
      end
    end

    def create_association(from_object_type, to_object_type)
      url = "/crm/v3/associations/#{from_object_type}/#{to_object_type}/batch/create"
      response = post_request(url, body)

      handle_created_responce(response)
    end

    def search_object(object_type)
      url = "/crm/v3/objects/#{object_type}/search"
      response = post_request(url, body)

      if response.code == 200
        response.parsed_response["results"]&.first
      else
        handle_error(response)
      end
    end

    def create_objects(object_type)
      url = "/crm/v3/objects/#{object_type}"
      response = post_request(url, body)

      handle_created_responce(response)
    end

    def fetch_object_by_deal_id(object_type)
      url = "/crm/v4/objects/deals/#{body[:deal_id]}/associations/#{object_type}"
      response = get_request(url)

      if response["errors"] && response["errors"].any?
        raise response["errors"].collect { |a| a["message"] }.join(",")
      end
      response.parsed_response["results"]&.first
    end

    def update_contact
      contact_id = body.delete(:contactId)
      update_object("contacts/#{contact_id}", { 'properties': body })
    end

    def update_deal
      deal_id = body.delete(:deal_id)
      update_object("deals/#{deal_id}", { 'properties': body })
    end

    def update_company
      company_id = body.delete(:companyId)
      update_object("companies/#{company_id}", { 'properties': body })
    end

    def update_order
      order_id = body[:properties].delete(:order_id)
      update_object("orders/#{order_id}", body)
    end

    def get_object_by_id(url)
      response = get_request(url)

      if response["errors"] && response["errors"].any?
        raise response["errors"].collect { |a| a["message"] }.join(",")
      end
      response.parsed_response["properties"]
    end

    private
      def update_object(object_type_and_id, body)
        url = "/crm/v3/objects/#{object_type_and_id}"
        response = patch_request(url, body)

        if response.code == 200
          response.parsed_response
        else
          handle_error(response)
        end
      end

      def post_request(url, body)
        HTTParty.post(
          "#{BASE_URL}#{url}",
          body: body.to_json,
          headers: headers
        )
      end

      def get_request(url)
        HTTParty.get(
          "#{BASE_URL}#{url}",
          headers: headers
        )
      end

      def patch_request(url, body)
        HTTParty.patch(
          "#{BASE_URL}#{url}",
          body: body.to_json,
          headers: headers
        )
      end

      def handle_created_responce(response)
        if response.code == 201
          response.parsed_response
        else
          handle_error(response)
        end
      end

      def handle_error(response)
        raise response.parsed_response["errors"].map { |e| e["message"] }.join(", ")
      end

      def headers
        {
          "Content-Type": "application/json",
          "Authorization": "Bearer #{ENV['HUBSPOT_ACCESS_TOKEN']}"
        }
      end
  end
end
