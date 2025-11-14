class HubspotsController < ApplicationController
  protect_from_forgery with: :null_session

  def create_opportunity
    @hubspot = Hubspot::Deal.new(params["hubspot"])
    @hubspot.sync_with_netsuite
    render json: { success: true }
  end

  def create_quote
    @hubspot = Hubspot::Deal.new(params["hubspot"])
    byebug
    @hubspot.sync_quotes_with_netsuite
    render json: { success: true }
  end
end
