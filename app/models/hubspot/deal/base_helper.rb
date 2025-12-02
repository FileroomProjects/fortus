module Hubspot::Deal::BaseHelper
  extend ActiveSupport::Concern

  include Hubspot::Deal::NetsuiteOpportunityHelper
  include Hubspot::Deal::NetsuiteContactHelper
  include Hubspot::Deal::NetsuiteCompanyHelper
  include Hubspot::Deal::NetsuiteQuoteHelper
  include Hubspot::Deal::HubspotQuoteDealHelper

  included do
  end
end
