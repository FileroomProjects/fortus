class HubspotsController < ApplicationController
  protect_from_forgery with: :null_session

  def callback
    @hubspot = Hubspot::Deal.new(params["hubspot"])
    @hubspot.sync_with_netsuite
    render json: { success: true }
  end
end
