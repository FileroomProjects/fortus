class Netsuite::Customer
  def self.create(args = {})
    client = Netsuite::Client.new(args)
    client.create_object("customer")
  end

  def self.update(ns_customer_id, args = {})
    client = Netsuite::Client.new(args)
    result = client.update_object("customer", ns_customer_id)
    # NetSuite PATCH often returns 204 without a Location header.
    { id: result[:id].presence || ns_customer_id }.with_indifferent_access
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
