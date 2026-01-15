namespace :netsuite do
  desc "Refresh NetSuite access token to prevent expiration"
  task refresh_token: :environment do
    begin
      success = Netsuite::Base.refresh_token_proactively
      if success
        puts "✓ NetSuite access token refreshed successfully"
      else
        puts "✗ Failed to refresh token: No refresh token available"
        exit 1
      end
    rescue => e
      puts "✗ Error refreshing NetSuite access token: #{e.message}"
      Rails.logger.error "[ERROR] [AUTH.NETSUITE] [FAIL] [provider:netsuite] Rake task failed: #{e.message}"
      exit 1
    end
  end
end
