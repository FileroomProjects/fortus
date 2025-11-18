class HubspotsController < ApplicationController
  protect_from_forgery with: :null_session

  def create_contact_customer
    @hubspot = Hubspot::Deal.new(params["hubspot"])
    @hubspot.sync_contact_customer_with_netsuite
    render json: { success: true }
  end

  def create_quote_opportunity
    @hubspot = Hubspot::Deal.new(params["hubspot"])
    @hubspot.sync_quotes_and_opportunity_with_netsuite
    render json: { success: true }
  end
end
