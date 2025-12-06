class HubspotsController < ApplicationController
  protect_from_forgery with: :null_session
  before_action :load_deal, only: [ :create_duplicate_ns_quote, :create_ns_quote ]

  def create_contact_customer
    @hubspot = Hubspot::Deal.new(params["hubspot"])
    @hubspot.sync_contact_customer_with_netsuite
    render json: { success: true }
  end

  def create_ns_quote
    payload = @hubspot.prepare_payload_for_netsuite_estimate
    @ns_estimate = @hubspot.create_ns_estimate(payload)

    respond_to { |format| format.html }
  end

  def create_duplicate_ns_quote
    payload = @hubspot.prepare_payload_for_duplicate_netsuite_estimate
    @ns_estimate = @hubspot.create_ns_estimate(payload)

    respond_to { |format| format.html }
  end

  private
    def load_deal
      deal_id = params[:deal_id] || params[:dealId]
      @hs_deal = Hubspot::Deal.find_by(deal_id: deal_id)

      unless @hs_deal.present?
        render json: { error: "Deal not found" }, status: :not_found and return
      end

      @hubspot = Hubspot::Deal.new(@hs_deal)
    end
end
