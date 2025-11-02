module Netsuite
  class Base
    include HTTParty
 
    
    # Exchange authorization code for access token and store it
    def self.exchange_code_for_token(code)
      token_url = "https://#{ENV['NETSUITE_ACCOUNT_ID']}.suitetalk.api.netsuite.com/services/rest/auth/oauth2/v1/token"

      response = HTTParty.post(token_url, {
        body: {
          grant_type: 'authorization_code',
          code: code,
          redirect_uri: ENV['NETSUITE_REDIRECT_URI'],
          client_id: ENV['NETSUITE_CLIENT_ID'],
          client_secret: ENV['NETSUITE_CLIENT_SECRET']
        },
        headers: {
          'Content-Type' => 'application/x-www-form-urlencoded',
          'Accept' => 'application/json'
        }
      })
      
      if response.success?
        token_data = response.parsed_response
        
        # Store access token in database
        Token.update_netsuite_token(
          access_token: token_data['access_token'],
          refresh_token: token_data['refresh_token'],
          expires_in: token_data['expires_in']
        )
        
        token_data
      else
        raise "Token exchange failed: #{response.body}"
      end
    end
    
    # Get current access token (refreshes if expired)
    def self.get_access_token
      token_record = Token.last
      return nil unless token_record&.access_token
      
      # Refresh if expired or about to expire
      if token_record.expired? || token_record.expires_in_seconds < 300
        refresh_access_token
        token_record.reload
      end
      
      token_record.access_token
    end
    
    private
    
    def self.refresh_access_token
      token_record = Token.netsuite_token
      return unless token_record&.refresh_token
      
      token_url = "https://#{ENV['NETSUITE_ACCOUNT_ID']}.suitetalk.api.netsuite.com/services/rest/auth/oauth2/v1/token"
      
      response = HTTParty.post(token_url, {
        body: {
          grant_type: 'refresh_token',
          refresh_token: token_record.refresh_token,
          client_id: ENV['NETSUITE_CLIENT_ID'],
          client_secret: ENV['NETSUITE_CLIENT_SECRET']
        },
        headers: {
          'Content-Type' => 'application/x-www-form-urlencoded',
          'Accept' => 'application/json'
        }
      })
      
      if response.success?
        token_data = response.parsed_response
        
        # Update existing token record
        Token.update_netsuite_token(
          access_token: token_data['access_token'],
          refresh_token: token_record.refresh_token, # Keep existing refresh token
          expires_in: token_data['expires_in']
        )
        
        token_data
      else
        raise "Token refresh failed: #{response.body}"
      end
    end
  end
end