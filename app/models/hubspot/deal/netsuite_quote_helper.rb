module Hubspot::Deal::NetsuiteQuoteHelper
  extend ActiveSupport::Concern

  included do
    def prepare_payload_for_netsuite_quote
      {
        "entity": { "id": "141139" },
        "custbody_so_title": "Road Repair Estimate",
        "location": { "id": "80" },
        "custbody34": "2024-11-05T08:30:00Z",
        "custbody20": { refName: "E-mail" },
        "custbody37": { "id": "6" },
        "custbody_phone_number": "4843211147",
        "item": {
          "items": [
            {
              "item": { "id": "2266" },
              "quantity": 1,
              "rate": 500
            }
          ]
        }
      }
    end
  end
end
