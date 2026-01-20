require 'httparty'
require 'json'

module Netsuite
  class RestletNote
    include HTTParty

    def initialize(skip_validation: false)
      @account = ENV['NETSUITE_ACCOUNT_ID'] || '4800298-sb1'
      @script_id = 'customscript3621'
      @deploy_id = 'customdeploy1'
      # Get fresh token - will be refreshed if needed by get_access_token
      @access_token = Netsuite::Base.get_access_token
      
      validate_restlet_endpoint! unless skip_validation
    end

    def create_note(opportunity_id:, note:, title: nil)
      url = "https://#{@account}.app.netsuite.com/app/site/hosting/restlet.nl?script=#{@script_id}&deploy=#{@deploy_id}"
      
      opportunity_id_int = opportunity_id.to_s.match?(/^\d+$/) ? opportunity_id.to_i : opportunity_id
      
      payload = {
        opportunity_id: opportunity_id_int,
        note: note
      }
      payload[:title] = title if title.present?
      
      # Refresh token before API call to ensure it's fresh (especially important on Heroku)
      refresh_token_if_needed
      
      response = HTTParty.post(url, {
        body: payload.to_json,
        headers: {
          "Authorization" => "Bearer #{@access_token}",
          "Content-Type" => "application/json"
        }
      })
      
      # If we get a 401, refresh token and retry once
      if response.code.to_i == 401
        Rails.logger.warn "[WARN] [RESTLET.NETSUITE] [RETRY] Got 401, refreshing token and retrying"
        refresh_token
        response = HTTParty.post(url, {
          body: payload.to_json,
          headers: {
            "Authorization" => "Bearer #{@access_token}",
            "Content-Type" => "application/json"
          }
        })
      end
      
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

    def refresh_token_if_needed
      # Always get fresh token to ensure it's in sync with database
      # get_access_token will refresh if expired or about to expire
      @access_token = Netsuite::Base.get_access_token
    end

    def refresh_token
      Rails.logger.info "[INFO] [RESTLET.NETSUITE] [REFRESH] Refreshing access token"
      @access_token = Netsuite::Base.get_access_token
    end

    def validate_restlet_endpoint!
      url = "https://#{@account}.app.netsuite.com/app/site/hosting/restlet.nl?script=#{@script_id}&deploy=#{@deploy_id}"
      
      # Always get fresh token before validation to ensure it's valid
      @access_token = Netsuite::Base.get_access_token
      
      response = HTTParty.get(url, {
        headers: {
          "Authorization" => "Bearer #{@access_token}"
        }
      })
      
      # If we get a 401, try refreshing token and retry once
      if response.code.to_i == 401
        Rails.logger.warn "[WARN] [RESTLET.NETSUITE] [VALIDATION] Got 401 during validation, refreshing token and retrying"
        refresh_token
        response = HTTParty.get(url, {
          headers: {
            "Authorization" => "Bearer #{@access_token}"
          }
        })
      end
      
      unless response.code.to_i == 200
        raise "RESTlet endpoint error: HTTP #{response.code} - #{response.body}"
      end
    end
  end
end
