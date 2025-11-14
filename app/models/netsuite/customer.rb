class Netsuite::Customer
  BASE_URL = "https://#{ENV['NETSUITE_ACCOUNT_ID']}.suitetalk.api.netsuite.com/services/rest/record/v1"

  def self.find_or_create_from_hubspot(hs_deal)
    service = new(hs_deal)
    service.find_or_create
  end

  def initialize(hs_deal)
    @hs_deal = hs_deal
    @token = ENV["NETSUITE_ACCESS_TOKEN"]
  end

  def find_or_create
    email = hubspot_email
    return nil unless email.present?

    # -------------------------------
    # STEP 1: SEARCH CUSTOMER BY EMAIL
    # -------------------------------
    customer_id = search_customer(email)
    return customer_id if customer_id

    # -------------------------------
    # STEP 2: CREATE CUSTOMER
    # -------------------------------
    create_customer
  end

  def self.create(args = {})
    @client = Netsuite::Client.new(args)
    @client.create_customer
  end

  def self.find_by(args = {})
    @client = Netsuite::Client.new(args)
    customer = @client.search_customer_by_properties
    if customer.present?
      customer = customer.with_indifferent_access
    end
    customer
  end

  private

  # ------------------------------------------------------------
  # Extract email from HubSpot deal → associated contact
  # ------------------------------------------------------------
  def hubspot_email
    @hs_deal.dig("properties", "email") ||
      @hs_deal.dig("associations", "contacts", 0, "email")
  end

  # ------------------------------------------------------------
  # NetSuite search customer by email
  # Valid operator for email is IS (not EQUAL/CONTAIN)
  # ------------------------------------------------------------
  def search_customer(email)
    query = "email IS \"#{email}\""

    resp = HTTParty.get(
      "#{BASE_URL}/customer",
      query: { q: query, limit: 1 },
      headers: headers
    )

    return nil unless resp.code == 200

    if resp["count"].to_i > 0
      return resp["items"][0]["id"]
    end

    nil
  end

  # ------------------------------------------------------------
  # Create new NetSuite customer from HubSpot data
  # ------------------------------------------------------------
  def create_customer
    body = {
      isPerson: true,
      firstName: contact_first_name,
      lastName: contact_last_name,
      email: hubspot_email,
      companyName: hs_company,
      phone: hs_phone
    }.compact

    resp = HTTParty.post(
      "#{BASE_URL}/customer",
      body: body.to_json,
      headers: headers
    )

    if resp.code == 201 || resp.code == 200
      return resp["id"]
    end

    raise "NetSuite Customer Create Error: #{resp.body}"
  end

  # ------------------------------------------------------------
  # HubSpot → NetSuite Field Mapping
  # ------------------------------------------------------------

  def contact_first_name
    @hs_deal.dig("properties", "firstname") ||
      @hs_deal.dig("contact", "firstname")
  end

  def contact_last_name
    @hs_deal.dig("properties", "lastname") ||
      @hs_deal.dig("contact", "lastname")
  end

  def hs_company
    @hs_deal.dig("properties", "company")
  end

  def hs_phone
    @hs_deal.dig("properties", "phone")
  end

  # ------------------------------------------------------------
  # Common headers
  # ------------------------------------------------------------
  def headers
    {
      "Authorization" => "Bearer #{@token}",
      "Content-Type"  => "application/json"
    }
  end
end
