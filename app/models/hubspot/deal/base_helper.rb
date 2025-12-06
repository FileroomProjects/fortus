module Hubspot::Deal::BaseHelper
  extend ActiveSupport::Concern

  include Hubspot::Deal::NetsuiteOpportunityHelper
  include Hubspot::Deal::NetsuiteContactHelper
  include Hubspot::Deal::NetsuiteCompanyHelper
  include Hubspot::Deal::NetsuiteEstimateHelper
  include Hubspot::Deal::HubspotChildDealHelper

  included do
  end
end
