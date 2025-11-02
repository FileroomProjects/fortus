module Hubspot
  class Deal < Hubspot::Base
    
    def associated_company
    end

    def associated_contact
    end

    def sync_with_netsuite
      @payload = prepare_payload_for_netsuite
    end

    def prepare_payload_for_netsuite
      {

      }
    end
  end
end
