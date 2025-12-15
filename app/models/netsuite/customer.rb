class Netsuite::Customer
  def self.create(args = {})
    client = Netsuite::Client.new(args)
    client.create_object("customer")
  end

  def self.find_by(args = {})
    client = Netsuite::Client.new(args)
    customer = client.search_customer_by_properties
    customer&.with_indifferent_access
  end

  def self.show(ns_customer_id)
    client = Netsuite::Client.new({})
    customer = client.fetch_object("customer", ns_customer_id)
    customer&.with_indifferent_access
  end
end
