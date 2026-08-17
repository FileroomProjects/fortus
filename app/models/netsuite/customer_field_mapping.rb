module Netsuite
  # Maps NetSuite Customer fields ↔ HubSpot Company properties.
  #
  # NetSuite keys are tried in order so both REST API field names and custom
  # webhook payload keys (often matching HubSpot internal IDs) are supported.
  module CustomerFieldMapping
    MAPPINGS = [
      { ns: %w[companyName name], hs: "name", direction: :both },
      { ns: %w[entityStatus status netsuite_status], hs: "netsuite_status", direction: :ns_to_hs, prefer: :ref_name },
      { ns: %w[url website], hs: "website", direction: :both },
      { ns: %w[custentity49 customerCategory netsuite_customer_category], hs: "netsuite_customer_category", direction: :ns_to_hs, prefer: :ref_name },
      { ns: %w[category netsuite_category], hs: "netsuite_category", direction: :ns_to_hs, prefer: :ref_name },
      { ns: %w[comments netsuite_comments_customer_history], hs: "netsuite_comments_customer_history", direction: :ns_to_hs },
      { ns: %w[netsuite_whale_account], hs: "netsuite_whale_account", direction: :ns_to_hs, prefer: :ref_name },
      { ns: %w[netsuite_named_account], hs: "netsuite_named_account", direction: :ns_to_hs, prefer: :ref_name },
      { ns: %w[netsuite_default_branch defaultBranch], hs: "netsuite_default_branch", direction: :ns_to_hs, prefer: :ref_name },
      { ns: %w[netsuite_internal_id_of_default_branch defaultBranch], hs: "netsuite_internal_id_of_default_branch", direction: :ns_to_hs, prefer: :id },
      { ns: %w[netsuite_bad_debt_writeoff], hs: "netsuite_bad_debt_writeoff", direction: :ns_to_hs },
      { ns: %w[netsuite_accounts_email], hs: "netsuite_accounts_email", direction: :ns_to_hs },
      { ns: %w[netsuite_accounts_cc_email], hs: "netsuite_accounts_cc_email", direction: :ns_to_hs },
      { ns: %w[phone], hs: "phone", direction: :both },
      # Address is NS→HS via defaultAddress; HS→NS write is skipped (addressbook structure).
      { ns: %w[defaultAddress address], hs: "address", direction: :both },
      { ns: %w[netsuite_email_address_for_payment_notification], hs: "netsuite_email_address_for_payment_notification", direction: :ns_to_hs },
      { ns: %w[fax netsuite_fax], hs: "netsuite_fax", direction: :ns_to_hs },
      { ns: %w[netsuite_last_invoice_contact_first_name], hs: "netsuite_last_invoice_contact_first_name", direction: :ns_to_hs },
      { ns: %w[subsidiary netsuite_primary_subsidiary], hs: "netsuite_primary_subsidiary", direction: :ns_to_hs, prefer: :ref_name },
      { ns: %w[netsuite_special_instructions], hs: "netsuite_special_instructions", direction: :ns_to_hs },
      { ns: %w[representsSubsidiary netsuite_represents_subsidiary], hs: "netsuite_represents_subsidiary", direction: :ns_to_hs, prefer: :ref_name },
      { ns: %w[netsuite_type_of_machine], hs: "netsuite_type_of_machine", direction: :ns_to_hs, prefer: :ref_name },
      { ns: %w[netsuite_fortus_machine_model], hs: "netsuite_fortus_machine_model", direction: :ns_to_hs, prefer: :ref_name },
      { ns: %w[netsuite_fortus_machine_qty], hs: "netsuite_fortus_machine_qty", direction: :ns_to_hs },
      { ns: %w[netsuite_customer_buying_preference], hs: "netsuite_customer_buying_preference", direction: :ns_to_hs, prefer: :ref_name },
      { ns: %w[netsuite_copy_item_pricing], hs: "netsuite_copy_item_pricing", direction: :ns_to_hs },
      { ns: %w[netsuite_named_account_yn], hs: "netsuite_named_account_yn", direction: :ns_to_hs },
      { ns: %w[netsuite_whale_account_yn], hs: "netsuite_whale_account_yn", direction: :ns_to_hs },
      { ns: %w[account_at_risk_yn], hs: "account_at_risk_yn", direction: :ns_to_hs },
      { ns: %w[salesRep netsuite_sales_rep], hs: "netsuite_sales_rep", direction: :ns_to_hs, prefer: :ref_name },
      { ns: %w[netsuite_customer_tier], hs: "netsuite_customer_tier", direction: :ns_to_hs, prefer: :ref_name },
      { ns: %w[netsuite_estimated_monthly_spend], hs: "netsuite_estimated_monthly_spend", direction: :ns_to_hs },
      { ns: %w[netsuite_dunning_stage], hs: "netsuite_dunning_stage", direction: :ns_to_hs, prefer: :ref_name },
      { ns: %w[netsuite_abn], hs: "netsuite_abn", direction: :ns_to_hs },
      { ns: %w[netsuite_additional_email], hs: "netsuite_additional_email", direction: :ns_to_hs },
      { ns: %w[netsuite_early_payment_reminder__opt_out], hs: "netsuite_early_payment_reminder__opt_out", direction: :ns_to_hs },
      { ns: %w[netsuite_last_sales_activity], hs: "netsuite_last_sales_activity", direction: :ns_to_hs }
    ].freeze

    HS_TO_NS_SKIP_KEYS = %w[defaultAddress address].freeze

    module_function

    def hubspot_properties_from_customer(customer, netsuite_company_id: nil)
      customer = (customer || {}).with_indifferent_access
      properties = {}

      MAPPINGS.each do |mapping|
        next unless %i[ns_to_hs both].include?(mapping[:direction])

        value = extract_value(customer, mapping[:ns], prefer: mapping[:prefer] || :raw)
        next if value.nil? || value == ""

        properties[mapping[:hs]] = normalize_hubspot_value(value)
      end

      properties["netsuite_company_id"] = netsuite_company_id.to_s if netsuite_company_id.present?
      properties["name"] ||= customer[:companyName].presence || customer[:name].presence || customer[:entityId].presence
      properties.compact
    end

    def netsuite_payload_from_hubspot_company(hs_company_details)
      details = (hs_company_details || {}).with_indifferent_access
      payload = {}

      MAPPINGS.each do |mapping|
        next unless %i[hs_to_ns both].include?(mapping[:direction])

        value = hubspot_field_value(details, mapping[:hs])
        next if value.blank?

        ns_key = mapping[:ns].find { |key| key.match?(/\A[a-z]/i) } || mapping[:ns].first
        next if HS_TO_NS_SKIP_KEYS.include?(ns_key)

        value = normalize_netsuite_url(value) if ns_key == "url"
        next if value.blank?

        payload[ns_key] = value
      end

      payload.compact
    end

    # NetSuite requires url to start with http://, https://, ftp://, or file://.
    def normalize_netsuite_url(value)
      url = value.to_s.strip
      return if url.blank?

      return url if url.match?(/\A(https?|ftp|file):\/\//i)

      "https://#{url}"
    end

    def extract_value(customer, keys, prefer: :raw)
      keys.each do |key|
        raw = customer[key]
        next if raw.nil? || raw == ""

        return format_nested_value(raw, prefer)
      end
      nil
    end

    def format_nested_value(raw, prefer)
      return raw unless raw.is_a?(Hash)

      hash = raw.with_indifferent_access
      case prefer
      when :id
        hash[:id].presence || hash[:refName]
      when :ref_name
        hash[:refName].presence || hash[:id]
      else
        hash[:refName].presence || hash[:id].presence || hash[:value].presence || raw
      end
    end

    def normalize_hubspot_value(value)
      case value
      when true, false
        value.to_s
      else
        value.is_a?(String) || value.is_a?(Numeric) ? value : value.to_s
      end
    end

    def hubspot_field_value(details, key)
      field = details[key]
      return if field.blank?

      field.is_a?(Hash) ? field["value"].presence || field[:value] : field
    end
  end
end
