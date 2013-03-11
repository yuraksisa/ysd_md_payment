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
    property :status, String, :field => 'status', :length => 10, :default => 'PENDING'
    property :payment_method, String, :field => 'payment_method', :length => 30

  end
end