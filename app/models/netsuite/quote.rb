module Netsuite::Quote
  def self.create(args = {})
    @client = Netsuite::Client.new(args)
    @client.create_quote
  end
end
