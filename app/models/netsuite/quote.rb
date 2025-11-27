module Netsuite::Quote
  def self.create(args = {})
    client = Netsuite::Client.new(args)
    client.create_quote
  end

  def self.show(ns_quote_id)
    client = Netsuite::Client.new({})
    quote = client.fetch_object("estimate/#{ns_quote_id}")
    quote&.with_indifferent_access
  end
end
