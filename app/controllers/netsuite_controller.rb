class NetsuiteController < ApplicationController
  # GET /netsuite/callback
  def callback
    code = params[:code]
    error = params[:error]
    
    if error
      render json: { error: "OAuth2 error: #{error}", description: params[:error_description] }, status: :bad_request
      return
    end
    
    unless code
      render json: { error: "Authorization code not provided" }, status: :bad_request
      return
    end
    
    begin
      # Use the class method directly
      token_data = Netsuite::Base.exchange_code_for_token(code)
      
      respond_to do |format|
        format.html do
          flash[:notice] = "NetSuite authentication successful!"
          redirect_to root_path
        end
        format.json { render json: { message: "Authentication successful", token_data: token_data } }
      end
      
    rescue => e
      Rails.logger.error "NetSuite OAuth2 error: #{e.message}"
      
      respond_to do |format|
        format.html do
          flash[:alert] = "NetSuite authentication failed: #{e.message}"
          redirect_to root_path
        end
        format.json { render json: { error: "Authentication failed", message: e.message }, status: :internal_server_error }
      end
    end
  end
end
