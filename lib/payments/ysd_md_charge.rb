require 'data_mapper' unless defined?DataMapper

module Payments

  #
  # It represents a charge
  #
  class Charge
    include DataMapper::Resource

    storage_names[:default] = 'payment_charges'

    property :id, Serial, :field => 'id'
    property :date, DateTime, :field => 'date', :default => lambda { |resource, property| Time.now }
    property :amount, Decimal, :field => 'amount', :precision => 10, :scale => 2
    property :currency, String, :field => 'currency', :length => 3
    property :status, Enum[:pending, :denied, :done], :field => 'status', :default => :pending
    property :payment_method_id, String, :field => 'payment_method_id', :length => 30

    #
    # Gets the payment method instance
    # 
    def payment_method
     @payment_method ||= PaymentMethod.get(payment_method_id.to_sym)
    end

  end
end