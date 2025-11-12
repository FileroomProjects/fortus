module Hubspot
  class Company < Hubspot::Base
    def self.fetch_by_deal_id(deal_id)
      body = { "inputs": [ { "id": "#{deal_id}" } ] }
      @client = Hubspot::Client.new(body: body)

      if company = @client.fetch_company
        company = company.first["to"]&.first
      end
      company.with_indifferent_access
    end

    def self.find_by_id(id)
      body = { id: id }
      @client = Hubspot::Client.new(body: body)

      if company = @client.fetch_company_by_id
        company = company.with_indifferent_access
      end
      company
    end

    def self.find_by_deal_id(deal_id)
      body = { deal_id: deal_id }
      @client = Hubspot::Client.new(body: body)

      if company = @client.fetch_company_by_deal
        company = company.with_indifferent_access
      end
      company
    end
  end
end
