require 'data_mapper' unless defined?DataMapper
require 'dm-types'
require 'ysd_md_yito' unless defined?Yito::Model::Finder

module Payments

  #
  # It represents a charge.
  #
  # A charge usually has a source that origins the charge. For example an 
  # order, a donation, a booking, ...
  #
  # To define the charge source you have to do the following :
  #
  # - In your charge source model, define a belongs_to property that links to
  #   to the charge
  #
  #   module Orders
  #     class Order 
  #       include DataMapper::Resource
  #       ...
  #       belongs_to :charge, 'Payments::Charge'
  #     end
  #   end
  #
  # - Open the Charge class to include the other part of the relationship, a
  #   has 1. The source have to be named xxx_charge_source to get retrieved
  #   by the charge_source method
  #
  #   module Payments
  #     class Charge
  #       has 1, :order_charge_source, 'Orders::Order'
  #     end
  #   end
  #
  #
  class Charge
    include DataMapper::Resource    
    extend Yito::Model::Finder

    storage_names[:default] = 'payment_charges'

    property :id, Serial, :field => 'id'
    property :date, DateTime, :field => 'date', :default => lambda { |resource, property| Time.now }
    property :amount, Decimal, :field => 'amount', :precision => 10, :scale => 2
    property :currency, String, :field => 'currency', :length => 3
    property :status, Enum[:pending, :processing, :denied, :done, :refunded], :field => 'status', :default => :pending
    property :payment_method_id, String, :field => 'payment_method_id', :length => 30
    property :origin, String, :field => 'origin'
    property :sales_channel_code, String, length: 50

    @loaded_charge_source = false
    @charge_source = nil
    
    #
    # Refund the charge
    #
    def refund
      update(:status => :refunded) if status == :done
    end

    def update(attributes)
      transaction do |t|
        super(attributes)
        t.commit
      end
    end

    #
    # Gets the payment method instance
    #
    # @return [PaymentMethod] The payment method instance 
    def payment_method
     @payment_method ||= PaymentMethod.get(payment_method_id.to_sym)
    end

    #
    # Gets the source of the charge
    #
    # @return [Object] the source of the charge
    def charge_source
      unless @loaded_charge_source 
        @charge_source = load_charge_source
        @loaded_charge_source = true
      end

      return @charge_source
    end

    #
    # Get the charge order if the source
    #
    def charge_order

      _charge_source = charge_source

      if _charge_source
        index = _charge_source.charge_source.charges.select { |c| c.status == :done }.sort { |x,y| x.date <=> y.date }.find_index(self)
        index += 1 unless index.nil?
      else
        return 0
      end

    end

    #
    # Charge detail
    #
    # @return [Array] Array of hashes with the following information
    #
    #    :item_reference
    #    :item_description
    #    :item_units
    #    :item_price
    #
    def detail
      
      result = []

      if charge_source and charge_source.respond_to?(:charge_detail)
        result.concat(charge_source.charge_detail)
      end  

      return result

    end
    
    #
    # Add the charge source
    #
    def as_json(opts={})
      
      methods = opts[:methods] || []
      methods << :charge_source

      super(opts.merge({:methods => methods}))

    end

    private
    
    #
    # Load the charge source
    #
    # @return [Object] the charge source
    #
    def load_charge_source

      candidates = relationships.select do |relationship|
         relationship.name =~ /_charge_source/ and (not relationship.get(self).nil?)
      end

      return (candidates.size>0)?candidates.first.get(self):nil

    end

  end
end