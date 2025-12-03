class HubspotsController < ApplicationController
  protect_from_forgery with: :null_session

  def create_contact_customer
    @hubspot = Hubspot::Deal.new(params["hubspot"])
    @hubspot.sync_contact_customer_with_netsuite
    render json: { success: true }
  end

  def create_ns_quote
    load_deal
    process_quote(
      :prepare_payload_for_netsuite_quote,
      :create_hubspot_quote_deal,
      @hs_deal[:dealId]
    )

    respond_to { |format| format.html }
  end

  def create_duplicate_ns_quote
    load_deal
    @parent_deal = @hubspot.find_parent_deal
    process_quote(
      :prepare_payload_for_duplicate_netsuite_quote,
      :create_duplicate_hubspot_quote_deal,
      @parent_deal[:id]
    )

    respond_to { |format| format.html }
  end

  private
    def load_deal
      deal_id = params[:deal_id] || params[:dealId]
      @hs_deal = Hubspot::Deal.find_by(deal_id: deal_id)
      @hubspot = Hubspot::Deal.new(@hs_deal)
    end

    def process_quote(payload_method, create_deal_method, parent_deal_id)
      payload = @hubspot.send(payload_method)
      @ns_quote = @hubspot.create_netsuite_quote_estimate(payload)
      @hs_deal_child = @hubspot.send(create_deal_method, @ns_quote)
      @hubspot.association_for_deal(@hs_deal_child[:id], parent_deal_id)
    end
end
