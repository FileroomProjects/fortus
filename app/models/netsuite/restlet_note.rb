require 'httparty'
require 'json'

module Netsuite
  class RestletNote
    include HTTParty

    def initialize(skip_validation: false)
      # Use environment variable for account ID to ensure consistency across environments
      @account = ENV['NETSUITE_ACCOUNT_ID'] || '4800298-sb1'
      @script_id = 'customscript3621'
      @deploy_id = 'customdeploy1'
      # Get fresh token - will be refreshed if needed by get_access_token
      @access_token = Netsuite::Base.get_access_token
      
      Rails.logger.info "[INFO] [RESTLET.NETSUITE] [INIT] Account: #{@account}, Environment: #{Rails.env}"
      
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
      original_token = access_token.dup # Store full token for comparison
      original_token_preview = access_token[0..20]
      
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
        Rails.logger.warn "[WARN] [RESTLET.NETSUITE] [RETRY] Original token (first 20 chars): #{original_token_preview}..."
        
        # Force a proactive refresh to ensure we get a completely fresh token
        refresh_success = Netsuite::Base.refresh_token_proactively
        
        if refresh_success
          Rails.logger.info "[INFO] [RESTLET.NETSUITE] [RETRY] Token refresh successful, getting new token"
          # Small delay to ensure token is fully committed to database
          sleep(0.5) if Rails.env.production?
          # Force database reload to get fresh token - use find_by to bypass any caching
          ActiveRecord::Base.connection.clear_query_cache
          # Get token directly from database without using scope (to avoid caching)
          token_record = Token.where(provider: "netsuite").order(created_at: :desc).first
          if token_record
            token_record.reload
            access_token = token_record.access_token
            new_token_preview = access_token[0..20]
            
          # Compare full tokens to verify they're different
          if access_token == original_token
            Rails.logger.warn "[WARN] [RESTLET.NETSUITE] [RETRY] Token is identical to original - NetSuite may have returned same token"
            Rails.logger.warn "[WARN] [RESTLET.NETSUITE] [RETRY] This suggests the token is valid but RESTlet authentication is failing"
            Rails.logger.warn "[WARN] [RESTLET.NETSUITE] [RETRY] Please verify RESTlet deployment is configured for OAuth 2.0 Token-Based Authentication"
          else
            Rails.logger.info "[INFO] [RESTLET.NETSUITE] [RETRY] New token obtained (first 20 chars): #{new_token_preview}... (different from original)"
          end
          else
            Rails.logger.error "[ERROR] [RESTLET.NETSUITE] [RETRY] No token record found after refresh!"
            access_token = get_fresh_token_for_request
          end
          
          headers["Authorization"] = "Bearer #{access_token}"
          response = HTTParty.post(url, {
            body: payload.to_json,
            headers: headers,
            timeout: 30
          })
          Rails.logger.info "[INFO] [RESTLET.NETSUITE] [RETRY] Status after retry: #{response.code}"
          Rails.logger.info "[INFO] [RESTLET.NETSUITE] [RETRY] Response body: #{response.body[0..200]}"
        else
          Rails.logger.error "[ERROR] [RESTLET.NETSUITE] [RETRY] Token refresh failed, cannot retry"
        end
      end
      
      parsed_response = response.parsed_response || response.body
      
      unless response.code.to_i.between?(200, 299)
        error_message = parsed_response.is_a?(Hash) ? parsed_response["error"] || parsed_response["message"] : parsed_response
        
        # If we get INVALID_LOGIN_ATTEMPT after retry, it's likely a RESTlet configuration issue
        if response.code.to_i == 401 && parsed_response.is_a?(Hash) && parsed_response.dig("error", "code") == "INVALID_LOGIN_ATTEMPT"
          Rails.logger.error "[ERROR] [RESTLET.NETSUITE] [AUTH] RESTlet authentication failed with INVALID_LOGIN_ATTEMPT"
          Rails.logger.error "[ERROR] [RESTLET.NETSUITE] [AUTH] Token is valid but RESTlet is rejecting it - this indicates a RESTlet deployment configuration issue"
          Rails.logger.error "[ERROR] [RESTLET.NETSUITE] [AUTH] Please verify in NetSuite: Customization > Scripting > Script Deployments > customdeploy1"
          Rails.logger.error "[ERROR] [RESTLET.NETSUITE] [AUTH] Authentication must be set to 'OAuth 2.0 Token-Based Authentication'"
        end
        
        return { 
          "success" => false,
          "error" => "HTTP #{response.code}", 
          "message" => error_message,
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
      
      # Log token details for debugging (first 20 chars only for security)
      token_record = Token.netsuite_token
      if token_record
        Rails.logger.info "[INFO] [RESTLET.NETSUITE] [TOKEN] Token present: #{token.present?}, Length: #{token.length}, Expired: #{token_record.expired?}, Expires in: #{token_record.expires_in_seconds}s, Token preview: #{token[0..20]}..."
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
