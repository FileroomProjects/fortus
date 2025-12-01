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
end
