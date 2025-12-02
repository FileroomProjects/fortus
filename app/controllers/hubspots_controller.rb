class HubspotsController < ApplicationController
  protect_from_forgery with: :null_session

  def create_contact_customer
    @hubspot = Hubspot::Deal.new(params["hubspot"])
    @hubspot.sync_contact_customer_with_netsuite
    render json: { success: true }
  end

  def create_ns_quote
    deal_id = params[:deal_id] || params[:dealId]
    @hs_deal = Hubspot::Deal.find_by(deal_id: deal_id)
    @hubspot = Hubspot::Deal.new(@hs_deal)
    @ns_quote = @hubspot.create_netsuite_quote_estimate_and_update_hubspot_deal
    @hs_deal_child = @hubspot.create_and_update_hubspot_quote_deal(@ns_quote)
    @hubspot.association_for_deal(@hs_deal_child[:id], deal_id)
    respond_to do |format|
      format.html { render :create_ns_quote }
    end
  end
end
