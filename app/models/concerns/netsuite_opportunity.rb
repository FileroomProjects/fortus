module NetsuiteOpportunity
  extend ActiveSupport::Concern

  included do
    def find_ns_opportunity_with_id(netsuite_opportunity_id)
      opportunity = Netsuite::Opportunity.show(netsuite_opportunity_id)

      unless object_present_with_id?(opportunity)
        Rails.logger.info "[INFO] [API.NETSUITE.OPPORTUNITY] [FETCH] [opportunity_id: #{opportunity[:id]}] Netsuite opportunity deatils not fetched"
        return nil
      end

      Rails.logger.info "[INFO] [API.NETSUITE.OPPORTUNITY] [FETCH] [opportunity_id: #{opportunity[:id]}] Netsuite opportunity deatils fetched"
      opportunity
    end

    def create_ns_oppportunity(payload)
      opportunity = Netsuite::Opportunity.create(payload)
      process_response("Netsuite Opportunity", "create", opportunity)
    end
  end
end
