module Hubspot::Deal::NetsuiteOpportunityHelper
  extend ActiveSupport::Concern

  included do
    ESTIMATE_STAGES = [
      { label: "Open", id: "1979552193" },
      { label: "Closed Won", id: "1979552198" },
      { label: "Closed Lost", id: "1979552199" }
    ].freeze

    def find_or_create_netsuite_opportunity
      if @netsuite_opportunity_id.blank?
        create_netsuite_opportunity_and_update_hubspot_deal
        return
      end

      ns_opportunity = find_ns_opportunity_with_id(@netsuite_opportunity_id)

      return  update_netsuite_opportunity(ns_opportunity) if object_present_with_id?(ns_opportunity)

      create_netsuite_opportunity_and_update_hubspot_deal
    end

    def create_netsuite_opportunity_and_update_hubspot_deal
      payload = prepare_payload_for_netsuite_opportunity
      ns_opportunity = create_ns_oppportunity(payload, deal_id)
      Rails.logger.info "[INFO] [SYNC.HUBSPOT_TO_NETSUITE.DEAL] [CREATE] [deal_id: #{deal_id}, opportunity_id: #{ns_opportunity[:id]}] Netsuite opportunity created successfully"

      @netsuite_opportunity_id = ns_opportunity[:id]

      update_hs_deal({ deal_id: deal_id, "netsuite_opportunity_id": ns_opportunity[:id] })

      Rails.logger.info "[INFO] [SYNC.HUBSPOT_TO_NETSUITE.DEAL] [UPDATE] [deal_id: #{deal_id}, opportunity_id: #{ns_opportunity[:id]}] HubSpot deal updated successfully"
      Rails.logger.info "[INFO] [SYNC.HUBSPOT_TO_NETSUITE.DEAL] [COMPLETE] [deal_id: #{deal_id}, opportunity_id: #{ns_opportunity[:id]}] Opportunity synchronized successfully"

      ns_opportunity
    end

    def update_netsuite_opportunity(ns_opportunity)
      payload = prepare_payload_for_netsuite_opportunity_update
      ns_opportunity = update_ns_opportunity(payload, ns_opportunity[:id], deal_id)

      Rails.logger.info "[INFO] [SYNC.HUBSPOT_TO_NETSUITE.DEAL] [UPDATE] [deal_id: #{deal_id}, opportunity_id: #{ns_opportunity[:id]}] Netsuite opportunity updated successfully"
      Rails.logger.info "[INFO] [SYNC.HUBSPOT_TO_NETSUITE.DEAL] [COMPLETE] [deal_id: #{deal_id}, opportunity_id: #{ns_opportunity[:id]}] Opportunity synchronized successfully"

      ns_opportunity
    end

    # Link a NetSuite opportunity to this HubSpot deal and sync key fields.
    def update_from_opportunity(opportunity)
      raise "Opportunity not found" if opportunity.blank? || opportunity[:id].blank?

      payload = {
        deal_id: deal_id,
        "netsuite_opportunity_id": opportunity[:id],
        "amount": opportunity[:total] || opportunity[:projectedTotal],
        "hs_deal_stage_probability": hubspot_probability_from_netsuite(opportunity[:probability]),
        "closedate": opportunity[:expectedCloseDate] || opportunity[:expectedClose],
        "dealname": opportunity[:title]
      }.compact

      updated_deal = update_hs_deal(payload)
      link_opportunity_company_and_contact(opportunity)
      Rails.logger.info "[INFO] [SYNC.NETSUITE_TO_HUBSPOT.OPPORTUNITY] [UPDATE] [deal_id: #{deal_id}, opportunity_id: #{opportunity[:id]}] HubSpot deal updated from opportunity"
      updated_deal
    end

    private
      def link_opportunity_company_and_contact(opportunity)
        hs_company = find_or_create_hs_company_from_opportunity(opportunity)
        hs_contact = find_or_create_hs_contact_from_opportunity(opportunity)

        associate_deal_with(hs_company[:id], "companies", "deal_to_company") if hs_company.present?
        associate_deal_with(hs_contact[:id], "contacts", "deal_to_contact") if hs_contact.present?
      end

      def find_or_create_hs_company_from_opportunity(opportunity)
        ns_customer_id = netsuite_ref_id(opportunity[:entity])
        if ns_customer_id.blank?
          Rails.logger.warn "[WARN] [SYNC.NETSUITE_TO_HUBSPOT.OPPORTUNITY] [SKIP] [deal_id: #{deal_id}] Opportunity has no entity/customer to link"
          return nil
        end

        hs_company = find_hs_company(
          [ build_search_filter("netsuite_company_id", "EQ", ns_customer_id) ],
          raise_error: false
        )
        return hs_company if object_present_with_id?(hs_company)

        ns_customer = Netsuite::Customer.show(ns_customer_id)
        create_hs_company({
          "properties": {
            "name": ns_customer[:companyName] || ns_customer[:entityId] || opportunity.dig(:entity, :refName),
            "netsuite_company_id": ns_customer_id
          }
        })
      end

      def find_or_create_hs_contact_from_opportunity(opportunity)
        ns_contact_id = opportunity_contact_id(opportunity)
        if ns_contact_id.blank?
          Rails.logger.warn "[WARN] [SYNC.NETSUITE_TO_HUBSPOT.OPPORTUNITY] [SKIP] [deal_id: #{deal_id}] Opportunity has no contact to link"
          return nil
        end

        Rails.logger.info "[INFO] [SYNC.NETSUITE_TO_HUBSPOT.OPPORTUNITY] [CONTACT] [deal_id: #{deal_id}, ns_contact_id: #{ns_contact_id}] Resolving HubSpot contact"

        hs_contact = find_hs_contact(
          [ build_search_filter("netsuite_contact_id", "EQ", ns_contact_id) ],
          raise_error: false
        )
        return hs_contact if object_present_with_id?(hs_contact)

        ns_contact = Netsuite::Contact.show(ns_contact_id)
        create_hs_contact({
          "properties": {
            "firstname": ns_contact[:firstName],
            "lastname": ns_contact[:lastName],
            "email": ns_contact[:email],
            "phone": ns_contact[:mobilePhone] || ns_contact[:phone],
            "jobtitle": ns_contact[:jobTitle],
            "netsuite_contact_id": ns_contact_id
          }.compact
        })
      end

      # Opportunity contact may live on `contact`, custom `custbody1`, links-only refs,
      # or only on the related customer — resolve in that order.
      def opportunity_contact_id(opportunity)
        netsuite_ref_id(opportunity[:contact]) ||
          netsuite_ref_id(opportunity[:custbody1]) ||
          contact_id_for_customer(netsuite_ref_id(opportunity[:entity]))
      end

      def contact_id_for_customer(ns_customer_id)
        return if ns_customer_id.blank?

        contact = Netsuite::Contact.find_by_company(ns_customer_id)
        return if contact.blank?

        netsuite_ref_id(contact)
      end

      def netsuite_ref_id(ref)
        return if ref.blank?
        return ref[:id].to_s if ref[:id].present?

        href = Array(ref[:links]).find { |link| link[:rel].to_s == "self" }&.dig(:href)
        href.to_s[%r{/(\d+)(?:\?|$)}, 1]
      end

      def associate_deal_with(to_object_id, to_object_type, association_type)
        payload = payload_to_associate(deal_id, to_object_id, association_type)
        results = Hubspot::Deal.create_association(payload, to_object_type)

        if results.blank?
          raise "Failed to associate deal #{deal_id} with #{to_object_type} #{to_object_id}"
        end

        Rails.logger.info "[INFO] [API.HUBSPOT.ASSOCIATION] [CREATE] [deal_id: #{deal_id}, #{to_object_type.singularize}_id: #{to_object_id}] Deal associated with #{to_object_type.singularize} successfully"
      end

      def get_stage_from_pl(stage_code)
        Hubspot::Deal::ESTIMATE_STAGES.select { |a| a[:id] == stage_code }.first[:label]
      end

      def prepare_payload_for_netsuite_opportunity
        payload = {
          "title": fetch_prop_field(:dealname),
          "custbody61": fetch_prop_field(:request_quote_notes),
          "custbodyhubspot_opportunity_quote_note": request_quote_triggered?,
          "memo": "Test opportunity created via API new",
          "tranDate": format_timestamp(fetch_prop_field(:createdate)),
          "expectedCloseDate": format_timestamp(fetch_prop_field(:closedate)),
          "status": "Open",
          "probability": fetch_prop_field(:hs_deal_stage_probability).to_f * 100, # Probability must be equal to or greater than 1.
          "entity": { "id": netsuite_company_id, "type": "customer" },
          "contact": { "id": netsuite_contact_id, "type": "contact" },
          "isBudgetApproved": false,
          "canHaveStackable": false,
          "shipIsResidential": false,
          "shipOverride": false,
          "rangeHigh": 0.0,
          "rangeLow": 0.0,
          "weightedTotal": 0.0,
          "totalCostEstimate": 0.0,
          "estGrossProfit": 0.0,
          "projectedTotal": fetch_prop_field(:hs_projected_amount).to_f,
          "total": fetch_prop_field(:hs_projected_amount).to_f,
          "custbody14": { "id": "120", "type": "customList" },
          "custbody61": fetch_prop_field(:request_quote_notes) # Use internal ID
        }
        sales_rep = netsuite_sales_rep
        payload["salesRep"] = sales_rep if sales_rep.present?
        payload
      end

      def format_timestamp(ms_timestamp)
        Time.at(ms_timestamp.to_i / 1000).utc.strftime("%Y-%m-%d")
      end

      # NetSuite stores probability as 0-100; HubSpot expects 0-1.
      def hubspot_probability_from_netsuite(probability)
        return if probability.blank?

        value = probability.to_f
        value > 1 ? value / 100.0 : value
      end

      def request_quote_triggered?
        fetch_prop_field(:request_quote_triggered) == "true"
      end

      def prepare_payload_for_netsuite_opportunity_update
        payload = {
          "custbody61": fetch_prop_field(:request_quote_notes)
        }
        sales_rep = netsuite_sales_rep
        payload["salesRep"] = sales_rep if sales_rep.present?
        payload
      end

      def netsuite_sales_rep
        employee_id = netsuite_employee_id_for_deal_owner
        return if employee_id.blank?

        { "id" => employee_id }
      end

      def netsuite_employee_id_for_deal_owner
        owner_id = fetch_prop_field(:hubspot_owner_id)
        return if owner_id.blank?

        owner_email = hubspot_owner_email(owner_id)
        return if owner_email.blank?

        find_netsuite_employee_id_by_email(owner_email)
      end

      def hubspot_owner_email(owner_id)
        response = HTTParty.get(
          "https://api.hubapi.com/crm/v3/owners/#{owner_id}",
          headers: {
            "Authorization" => "Bearer #{ENV['HUBSPOT_ACCESS_TOKEN']}",
            "Content-Type" => "application/json"
          }
        )
        return unless response.code == 200

        JSON.parse(response.body)["email"]
      rescue => e
        Rails.logger.error "[ERROR] [SYNC.HUBSPOT_TO_NETSUITE.DEAL] [OWNER] [deal_id: #{deal_id}, owner_id: #{owner_id}] Failed to fetch HubSpot owner: #{e.message}"
        nil
      end

      def find_netsuite_employee_id_by_email(email)
        response = HTTParty.get(
          "https://#{ENV['NETSUITE_ACCOUNT_ID']}.suitetalk.api.netsuite.com/services/rest/record/v1/employee",
          query: { q: "email IS \"#{email}\"" },
          headers: {
            "Authorization" => "Bearer #{Netsuite::Base.get_access_token}",
            "Content-Type" => "application/json"
          }
        )
        return unless response.code == 200

        JSON.parse(response.body)["items"]&.first&.dig("id")
      rescue => e
        Rails.logger.error "[ERROR] [SYNC.HUBSPOT_TO_NETSUITE.DEAL] [EMPLOYEE] [deal_id: #{deal_id}, email: #{email}] Failed to find NetSuite employee: #{e.message}"
        nil
      end
  end
end
