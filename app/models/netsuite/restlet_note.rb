require 'httparty'
require 'json'

module Netsuite
  class RestletNote
    include HTTParty

    def initialize(skip_validation: false)
      @account = ENV['NETSUITE_ACCOUNT_ID'] || '4800298-sb1'
      @script_id = 'customscript3621'
      @deploy_id = 'customdeploy1'
      @access_token = Netsuite::Base.get_access_token
      
      validate_restlet_endpoint! unless skip_validation
    end

    def create_note(opportunity_id:, note:, title: nil)
      url = "https://#{@account}.app.netsuite.com/app/site/hosting/restlet.nl?script=#{@script_id}&deploy=#{@deploy_id}"
      
      opportunity_id_int = opportunity_id.to_s.match?(/^\d+$/) ? opportunity_id.to_i : opportunity_id
      
      payload = {
        opportunity_id: 4449568,
        note: 'hello'
      }
      payload[:title] = title if title.present?
      
      response = HTTParty.post(url, {
        body: payload.to_json,
        headers: {
          "Authorization" => "Bearer #{@access_token}",
          "Content-Type" => "application/json"
        }
      })
      
      parsed_response = response.parsed_response || response.body
      
      unless response.code.to_i.between?(200, 299)
        return { 
          "success" => false,
          "error" => "HTTP #{response.code}", 
          "message" => parsed_response.is_a?(Hash) ? parsed_response["error"] || parsed_response["message"] : parsed_response,
          "http_code" => response.code,
          "raw_response" => parsed_response
        }
      end
      
      parsed_response
    rescue JSON::ParserError => e
      { 
        "success" => false,
        "error" => "Invalid JSON response", 
        "raw_response" => response.body, 
        "http_code" => response.code, 
        "exception" => e.message 
      }
    end

    private

    def validate_restlet_endpoint!
      url = "https://#{@account}.app.netsuite.com/app/site/hosting/restlet.nl?script=#{@script_id}&deploy=#{@deploy_id}"
      
      response = HTTParty.get(url, {
        headers: {
          "Authorization" => "Bearer #{@access_token}"
        }
      })
      
      unless response.code.to_i == 200
        raise "RESTlet endpoint error: HTTP #{response.code} - #{response.body}"
      end
    end
  end
end
