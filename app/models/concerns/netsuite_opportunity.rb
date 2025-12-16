module NetsuiteOpportunity
  extend ActiveSupport::Concern

  included do
    # Fetch a NetSuite opportunity by ID; return it if found, otherwise nil.
    def find_ns_opportunity_with_id(netsuite_opportunity_id)
      opportunity = Netsuite::Opportunity.show(netsuite_opportunity_id)

      unless object_present_with_id?(opportunity)
        Rails.logger.info "[INFO] [API.NETSUITE.OPPORTUNITY] [FETCH] [opportunity_id: #{opportunity[:id]}] Netsuite opportunity deatils not fetched"
        return nil
      end

      Rails.logger.info "[INFO] [API.NETSUITE.OPPORTUNITY] [FETCH] [opportunity_id: #{opportunity[:id]}] Netsuite opportunity deatils fetched"
      opportunity
    end

    # Create a NetSuite opportunity using the given payload.
    def create_ns_oppportunity(payload, deal_id)
      Rails.logger.info "[INFO] [SYNC.HUBSPOT_TO_NETSUITE.DEAL] [START] [deal_id: #{deal_id}] Initiating deal synchronization"
      opportunity = Netsuite::Opportunity.create(payload)
      process_response("Netsuite Opportunity", "create", opportunity)
    end

    # Update a NetSuite opportunity using the given payload.
    def update_ns_opportunity(payload, ns_opportunity_id, deal_id)
      Rails.logger.info "[INFO] [SYNC.HUBSPOT_TO_NETSUITE.DEAL] [START] [deal_id: #{deal_id}] Initiating deal synchronization"
      opportunity = Netsuite::Opportunity.update(payload, ns_opportunity_id)
      process_response("Netsuite Opportunity", "update", opportunity)
    end
  end
end
