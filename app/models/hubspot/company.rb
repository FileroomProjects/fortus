module Hubspot
  class Company < Hubspot::Base
    def self.fetch_by_deal_id(deal_id)
      body = { "inputs": [ { "id": "#{deal_id}" } ] }
      client = Hubspot::Client.new(body: body)

      company = client.fetch_company
      company = company&.first["to"]&.first
      company&.with_indifferent_access
    end

    def self.find_by_id(id)
      url = "/companies/v2/companies/#{id}"
      client = Hubspot::Client.new(body: {})

      company = client.get_object_by_id(url)
      company&.with_indifferent_access
    end

    def self.find_by_deal_id(deal_id)
      body = { from_object_id: deal_id }
      client = Hubspot::Client.new(body: body)

      companies = client.fetch_object_by_associated_object_id("deals", "companies")

      company = primary_company(companies)
      company&.with_indifferent_access
    end

    def self.update(args = {})
      client = Hubspot::Client.new(body: args)

      company = client.update_company
      company&.with_indifferent_access
    end

    def self.search(args = {})
      client = Hubspot::Client.new(body: args)

      company = client.search_object("companies")
      company&.with_indifferent_access
    end

    private
      def self.primary_company(companies)
        return unless companies.present?

        companies.find do |company|
          company["associationTypes"]&.any? { |a| a["label"] == "Primary" }
        end
      end
  end
end
