class HubspotsController < ApplicationController
  protect_from_forgery with: :null_session

  def create_contact_customer
    @hubspot = Hubspot::Deal.new(params["hubspot"])
    @hubspot.sync_contact_customer_with_netsuite
    render json: { success: true }
  end

  def create_ns_quote
    load_deal
    process_estimate(
      :prepare_payload_for_netsuite_estimate,
      :create_hubspot_child_deal,
      @hs_deal[:dealId]
    )

    respond_to { |format| format.html }
  end

  def create_duplicate_ns_quote
    load_deal
    @parent_deal = @hubspot.find_parent_deal
    process_estimate(
      :prepare_payload_for_duplicate_netsuite_estimate,
      :create_duplicate_hubspot_child_deal,
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

    def process_estimate(payload_method, create_deal_method, parent_deal_id)
      payload = @hubspot.send(payload_method)
      @ns_estimate = @hubspot.create_ns_estimate(payload)
      @hs_child_deal = @hubspot.send(create_deal_method, @ns_estimate)
      @hubspot.association_for_deal(@hs_child_deal[:id], parent_deal_id, @ns_estimate[:id])
    end
end
