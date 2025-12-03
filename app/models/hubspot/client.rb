module Hubspot
  class Client
    attr_accessor :body

    BASE_URL = "https://api.hubapi.com"
    include HttpsRequest

    def initialize(args)
      @body = args[:body]
    end

    def fetch_deal
      response = get("/deals/v1/deal/#{body[:deal_id]}")

      handle_error(response) unless response.code == 200

      response.parsed_response
    end

    def fetch_company
      response = post("/crm/v3/associations/deal/company/batch/read", body)

      handle_error(response) unless response.code == 200

      response.parsed_response["results"]
    end

    def create_association(from_object_type, to_object_type)
      response = post("/crm/v3/associations/#{from_object_type}/#{to_object_type}/batch/create", body)

      handle_created_responce(response)
    end

    def search_object(object_type)
      response = post("/crm/v3/objects/#{object_type}/search", body)

      handle_error(response) unless response.code == 200

      response.parsed_response["results"]&.first
    end

    def create_objects(object_type)
      response = post("/crm/v3/objects/#{object_type}", body)

      handle_created_responce(response)
    end

    def fetch_object_by_associated_object_id(from_object_type, object_type)
      url = "/crm/v4/objects/#{from_object_type}/#{body[:from_object_id]}/associations/#{object_type}"
      response = get(url)

      handle_error(response) unless response.code == 200

      response.parsed_response["results"]
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
      response = get(url)

      handle_error(response) unless response.code == 200

      response.parsed_response["properties"]
    end

    def update_object(object_type_and_id, body)
      url = "/crm/v3/objects/#{object_type_and_id}"
      response = patch_request(full_url(url), body, headers)

      handle_error(response) unless response.code == 200

      response.parsed_response
    end

    def remove_association(url)
      response = delete_request(full_url(url), headers)

      handle_error(response) unless response.code == 204

      "success"
    end

    private
      def handle_created_responce(response)
        handle_error(response) unless response.code == 201

        response.parsed_response
      end

      def get(path)
        get_request(full_url(path), headers)
      end

      def post(path, body)
        post_request(full_url(path), body, headers)
      end

      def full_url(path)
        "#{BASE_URL}#{path}"
      end

      def handle_error(response)
        if response.parsed_response["errors"].present?
          raise response.parsed_response["errors"].map { |e| e["message"] }.join(", ")
        else
          raise response.parsed_response["message"]
        end
      end

      def headers
        {
          "Content-Type": "application/json",
          "Authorization": "Bearer #{ENV['HUBSPOT_ACCESS_TOKEN']}"
        }
      end
  end
end
