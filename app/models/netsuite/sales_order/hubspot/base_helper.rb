module Netsuite::SalesOrder::Hubspot::BaseHelper
  extend ActiveSupport::Concern

  include Netsuite::SalesOrder::Hubspot::OrderHelper
  include Netsuite::SalesOrder::Hubspot::ContactHelper
  include Netsuite::SalesOrder::Hubspot::CompanyHelper
  include Netsuite::SalesOrder::Hubspot::DealHelper
  include Netsuite::SalesOrder::Hubspot::LineItemHelper

  included do
  end
end
