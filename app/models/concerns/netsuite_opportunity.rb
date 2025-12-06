module NetsuiteOpportunity
  extend ActiveSupport::Concern

  included do
    def find_ns_opportunity_with_id(netsuite_opportunity_id)
      opportunity = Netsuite::Opportunity.show(netsuite_opportunity_id)

      return nil unless object_present_with_id?(opportunity)

      info_log("Netsuite Opportunity already exists with ID #{opportunity[:id]}")
      opportunity
    end

    def create_ns_oppportunity(payload)
      opportunity = Netsuite::Opportunity.create(payload)
      process_response("Netsuite Opportunity", "create", opportunity)
    end
  end
end
