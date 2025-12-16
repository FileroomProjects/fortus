module Netsuite::Estimate::Hubspot::BaseHelper
  extend ActiveSupport::Concern

  include Netsuite::Estimate::Hubspot::DealHelper
  include Netsuite::Estimate::Hubspot::ChildDealHelper
  include Netsuite::Estimate::Hubspot::ContactHelper
  include Netsuite::Estimate::Hubspot::LineItemHelper
  include Netsuite::Estimate::Hubspot::CompanyHelper

  included do
  end
end
