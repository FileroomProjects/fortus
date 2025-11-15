module Hubspot
  class Base
    require "ostruct"
    attr_accessor :args, :properties

    def initialize(params)
      @args = params.as_json.with_indifferent_access
      @properties = @args[:properties] rescue {}
      @netsuite_opportunity_id = (fetch_prop_field(:netsuite_opportunity_id) rescue nil)
    end
  end
end
