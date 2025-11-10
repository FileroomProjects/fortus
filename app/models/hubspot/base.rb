module Hubspot
  class Base
    require "ostruct"
    attr_accessor :args, :properties

    def initialize(params)
      @args = params.as_json.with_indifferent_access
      @properties = @args[:properties] rescue {}
    end
  end
end
