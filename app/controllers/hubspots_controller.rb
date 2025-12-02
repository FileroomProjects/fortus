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
    payload = @hubspot.prepare_payload_for_netsuite_quote
    @ns_quote = @hubspot.create_netsuite_quote_estimate(payload)
    @hs_deal_child = @hubspot.create_hubspot_quote_deal(@ns_quote)
    @hubspot.association_for_deal(@hs_deal_child[:id], deal_id)
    respond_to do |format|
      format.html { render :create_ns_quote }
    end
  end

  def create_duplicate_ns_quote
    deal_id = params[:deal_id] || params[:dealId]
    @hs_deal = Hubspot::Deal.find_by(deal_id: deal_id)
    @hubspot = Hubspot::Deal.new(@hs_deal)
    payload = @hubspot.prepare_payload_for_duplicate_netsuite_quote
    @ns_quote = @hubspot.create_netsuite_quote_estimate(payload)
    @hs_deal_child = @hubspot.create_duplicate_hubspot_quote_deal(@ns_quote)
    @parent_deal = @hubspot.find_parent_deal
    @hubspot.association_for_deal(@hs_deal_child[:id], @parent_deal[:id])
    respond_to do |format|
      format.html { render :create_duplicate_ns_quote }
    end
  end
end
