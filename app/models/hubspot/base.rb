module Hubspot
  class Base
    require 'ostruct'
    attr_accessor :args
    

    def initialize(params)
      @args = params.as_json.with_indifferent_access
    end
  end
end