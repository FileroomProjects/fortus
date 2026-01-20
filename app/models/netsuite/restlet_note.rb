require 'httparty'
require 'json'

module Netsuite
  class RestletNote
    include HTTParty

    def initialize(skip_validation: false)
      @account = '4800298-sb1'
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
      
      # Always get a fresh token right before the API call (critical on Heroku)
      # Don't rely on cached token - get it fresh from database
      access_token = get_fresh_token_for_request
      
      # RESTlet headers - some RESTlets may require additional headers
      headers = {
        "Authorization" => "Bearer #{access_token}",
        "Content-Type" => "application/json",
        "Accept" => "application/json"
      }
      
      Rails.logger.info "[INFO] [RESTLET.NETSUITE] [REQUEST] Calling RESTlet: #{url}"
      Rails.logger.debug "[DEBUG] [RESTLET.NETSUITE] [PAYLOAD] #{payload.to_json}"
      
      response = HTTParty.post(url, {
        body: payload.to_json,
        headers: headers,
        timeout: 30
      })
      
      Rails.logger.info "[INFO] [RESTLET.NETSUITE] [RESPONSE] Status: #{response.code}, Body: #{response.body[0..200]}"
      
      # If we get a 401, force token refresh and retry once
      if response.code.to_i == 401
        Rails.logger.warn "[WARN] [RESTLET.NETSUITE] [RETRY] Got 401, forcing token refresh and retrying"
        Rails.logger.warn "[WARN] [RESTLET.NETSUITE] [RETRY] Response body: #{response.body}"
        
        # Force a proactive refresh to ensure we get a completely fresh token
        Netsuite::Base.refresh_token_proactively
        access_token = get_fresh_token_for_request
        
        headers["Authorization"] = "Bearer #{access_token}"
        response = HTTParty.post(url, {
          body: payload.to_json,
          headers: headers,
          timeout: 30
        })
        Rails.logger.info "[INFO] [RESTLET.NETSUITE] [RETRY] Status after retry: #{response.code}"
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

    def get_fresh_token_for_request
      # Always get a fresh token from the database right before making the request
      # This ensures we have the latest token, especially important on Heroku
      # where there might be connection pooling or timing issues
      token = Netsuite::Base.get_access_token
      
      # Verify token is present
      unless token.present?
        Rails.logger.error "[ERROR] [RESTLET.NETSUITE] [TOKEN] No access token available"
        raise "No NetSuite access token available"
      end
      
      token
    end

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
      access_token = get_fresh_token_for_request
      
      response = HTTParty.get(url, {
        headers: {
          "Authorization" => "Bearer #{access_token}"
        },
        timeout: 30
      })
      
      # If we get a 401, try refreshing token and retry once
      if response.code.to_i == 401
        Rails.logger.warn "[WARN] [RESTLET.NETSUITE] [VALIDATION] Got 401 during validation, refreshing token and retrying"
        Netsuite::Base.refresh_token_proactively
        access_token = get_fresh_token_for_request
        response = HTTParty.get(url, {
          headers: {
            "Authorization" => "Bearer #{access_token}"
          },
          timeout: 30
        })
      end
      
      unless response.code.to_i == 200
        raise "RESTlet endpoint error: HTTP #{response.code} - #{response.body}"
      end
    end
  end
end
