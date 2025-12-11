module Hubspot
  class Company < Hubspot::Base
    # Retrieve a company by HubSpot id and return its properties.
    def self.find_by_id(id)
      url = "/companies/v2/companies/#{id}"
      client = Hubspot::Client.new(body: {})

      company = client.get_object_by_id(url)
      company&.with_indifferent_access
    end

    # Find companies associated to a deal and return the primary company.
    def self.find_by_deal_id(deal_id)
      body = { from_object_id: deal_id }
      client = Hubspot::Client.new(body: body)

      companies = client.fetch_object_by_associated_object_id("deals", "companies")

      company = primary_company(companies)
      company&.with_indifferent_access
    end

    # Update a HubSpot company with provided args and return the updated object.
    def self.update(args = {})
      client = Hubspot::Client.new(body: args)

      company = client.update_company
      company&.with_indifferent_access
    end

    # Search HubSpot companies with given filters and return the first match.
    def self.search(args = {})
      client = Hubspot::Client.new(body: args)

      company = client.search_object("companies")
      company&.with_indifferent_access
    end

    # Create a new HubSpot company using the provided payload.
    def self.create(args = {})
      client = Hubspot::Client.new(body: args)
      company = client.create_objects("companies")
      company&.with_indifferent_access
    end

    private
      # From a list of associated companies, return the one marked Primary.
      def self.primary_company(companies)
        return unless companies.present?

        companies.find do |company|
          company["associationTypes"]&.any? { |a| a["label"] == "Primary" }
        end
      end
  end
end
