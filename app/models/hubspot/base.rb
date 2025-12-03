module Hubspot
  class Base
    require "ostruct"
    attr_accessor :args, :properties, :deal_id
    include IntegrationCommon

    def initialize(params)
      @args = params.as_json.with_indifferent_access
      @properties = @args[:properties] rescue {}
      @deal_id = @args[:objectId] || @args[:deal_id] || @args[:dealId]
      @netsuite_opportunity_id = (fetch_prop_field(:netsuite_opportunity_id) rescue nil)
    end
  end
end
