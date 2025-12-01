module HttpsRequest
  extend ActiveSupport::Concern

  included do
    def post_request(url, body, headers)
      HTTParty.post(url, body: body.to_json, headers: headers)
    end

    def patch_request(url, body, headers)
      HTTParty.patch(url, body: body.to_json, headers: headers)
    end

    def get_request(url, headers)
      HTTParty.get(url, headers: headers)
    end

    def delete_request(url, headers)
      HTTParty.delete(url, headers: headers)
    end

    def search_query(url, query, headers)
      HTTParty.get(url, query: query, headers: headers)
    end
  end
end
