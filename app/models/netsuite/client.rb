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
          'Authorization' => "Bearer #{access_token}",
          'Content-Type' => 'application/json'
        }
      )
      if response["errors"] && response["errors"].any?
        raise response["errors"].collect{|a| a["message"]}.join(',')
      end
      raise "Netsuite Client opportunity error :" + response.parsed_response["results"]&.first
    end

    def create_contact
      response = HTTParty.post(
        "https://#{ENV['NETSUITE_ACCOUNT_ID']}.suitetalk.api.netsuite.com/services/rest/record/v1/contact",
        body: body.to_json,
        headers: {
          'Authorization' => "Bearer #{access_token}",
          'Content-Type' => 'application/json'
        }
      )

      if response.code == 204
        ns_contact_id = response.headers[:location].split('/').last
        return { id: ns_contact_id }
      else
        raise "Netsuite Client Contact error :"  + response["errors"].collect{|a| a["message"]}.join(',')
      end
    end
  end
end
