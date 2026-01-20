module Netsuite
  class Base
    require "ostruct"

    include HTTParty
    include BaseConcern

    attr_accessor :args

    def initialize(params)
      @args = params.as_json.with_indifferent_access
    end

    # Exchange authorization code for access token and store it
    # Called during initial OAuth2 authentication flow
    def self.exchange_code_for_token(code)
      response = HTTParty.post(token_url, {
        body: {
          grant_type: "authorization_code",
          code: code,
          redirect_uri: ENV["NETSUITE_REDIRECT_URI"],
          client_id: ENV["NETSUITE_CLIENT_ID"],
          client_secret: ENV["NETSUITE_CLIENT_SECRET"]
        },
        headers: headers
      })

      raise "Token exchange failed: #{response.body}" unless response.success?

      token_data = response.parsed_response

      # Store access token in database
      Token.update_netsuite_token(
        access_token: token_data["access_token"],
        refresh_token: token_data["refresh_token"],
        expires_in: token_data["expires_in"]
      )

      token_data
    end

    # Get current access token (refreshes if expired)
    # Automatically refreshes token if it has expired or is about to expire (< 5 minutes)
    def self.get_access_token
      token_record = Token.netsuite_token
      return nil unless token_record&.access_token

      # Refresh if expired or about to expire
      if token_record.expired? || token_record.expires_in_seconds < 300
        refresh_access_token
        token_record.reload
      end

      token_record.access_token
    end

    # Public method to proactively refresh access token
    # Can be called from rake tasks or scheduled jobs
    def self.refresh_token_proactively
      token_record = Token.netsuite_token
      unless token_record&.refresh_token
        Rails.logger.warn "[WARN] [AUTH.NETSUITE] [SKIP] [provider:netsuite] No refresh token available"
        return false
      end

      Rails.logger.info "[INFO] [AUTH.NETSUITE] [REFRESH] [provider:netsuite] Proactively refreshing access token"
      refresh_access_token
      true
    end

    private
      def self.refresh_access_token
        Rails.logger.warn "[WARN] [AUTH.NETSUITE] [RETRY] [provider:netsuite] Token expired, refreshing access token"
        token_record = Token.netsuite_token
        # return unless token_record&.refresh_token

        response = HTTParty.post(token_url, {
          body: {
            grant_type: "refresh_token",
            refresh_token: token_record.refresh_token,
            client_id: ENV["NETSUITE_CLIENT_ID"],
            client_secret: ENV["NETSUITE_CLIENT_SECRET"]
          },
          headers: headers
        })

        unless response.success?
          raise ActionController::InvalidAuthenticityToken, "Token refresh failed: #{response.body}"
        end

        token_data = response.parsed_response

        # Update existing token record
        Token.update_netsuite_token(
          access_token: token_data["access_token"],
          refresh_token: token_record.refresh_token, # Keep existing refresh token
          expires_in: token_data["expires_in"]
        )

        token_data
      end

      def self.token_url
        "https://#{ENV['NETSUITE_ACCOUNT_ID']}.suitetalk.api.netsuite.com/services/rest/auth/oauth2/v1/token"
      end

      def self.headers
        {
          "Content-Type" => "application/x-www-form-urlencoded",
          "Accept" => "application/json"
        }
      end
  end
end
