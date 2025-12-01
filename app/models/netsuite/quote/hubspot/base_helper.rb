module Netsuite::Quote::Hubspot::BaseHelper
  extend ActiveSupport::Concern

  include Netsuite::Quote::Hubspot::DealHelper
  include Netsuite::Quote::Hubspot::ContactHelper
  include Netsuite::Quote::Hubspot::LineItemHelper
  include Netsuite::Quote::Hubspot::CompanyHelper

  included do
  end
end
