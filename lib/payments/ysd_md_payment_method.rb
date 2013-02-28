require 'ysd_md_configuration' unless defined?System::Variable

module Payments
  
  # 
  # Instances of this class represent payment method. 
  #
  # An application could use only a set of the defined payment methods. These
  # can be setup using the available= method o setting up the 
  # payments.available_methods SystemConfiguration::Variable
  # 
  # There are concrete classes for diferent types of payments process:
  #
  #  - gateway payment : (GatewayPaymentMethod)
  #
  #    They connect to the bank to make the charge. The customer credit card
  #    is not stored in the system.
  # 
  #  - offline payment : (OfflinePaymentMethod)
  #
  #    The customer makes a payment offline, making a bank transfer, sending
  #    a cheque, ...
  #
  # Usage:
  #
  #  ## Create a new payment method
  #
  #     sermepa = Payments::Payment.new(:sermepa, 
  #       :title => 'The title',
  #       :description => 'The description')
  #
  #  ## Get all payment methods
  #
  #     Payments::PaymentMethod.all
  #
  #  ## Define the application(available) payment methods
  #   
  #     Payments::PaymentMethod.available= [:paypal, :cecabank]
  #
  #     or
  #
  #     SystemConfiguration::Variable.set_value('payment.available_methods',
  #       'paypal, cecabank')
  #   
  #  ## Get the application(available) payment methods 
  #
  #     Payments::PaymentMehtod.available
  #
  #  ## Get a payment method instance (a concrete payment method)
  #
  #     cecabank = Payments::PaymentMethod.get(:cecabank)
  #
  #  ## charge (payment gateway method)
  #
  #     charge = cecabank.charge({:amount => 150.50, :currency => 'EUR'})
  #
  class PaymentMethod
     
     attr_accessor :id, :title, :description, :opts
   
     def initialize(id, opts={})
       @id = id
       @title = opts.delete(:title)
       @description = opts.delete(:description)
       @opts = opts
       PaymentMethod.payment_methods << self
     end

     #
     # Retrieve all payment methods
     #
     # @return [Array] with defined payment methods
     #
     def self.all
       payment_methods
     end
     
     #
     # Retrieve an concrete payment method by its id
     #
     # @param [String] the payment method id
     # @return [PaymentMethod] the payment method
     def self.get(id)
       all.select { |payment_method| payment_method.id == id}.first
     end

     #
     # Retrieve the payment methods available for the current application.
     # An application should only use the payment methods that have been
     # declared
     #
     # @return [Array] with the application available payment methods
     #
     def self.available

       all.select do |payment_method|
       	  SystemConfiguration::Variable.get_value('payments.available_methods')
       	    .split(',').map{|item| item.to_sym}.include? payment_method.id
       end

     end
     
     #
     # Configure the available payment methods
     #
     # @param [String or Array] the available methods
     #
     def self.available=(available_methods)

       if available_methods.is_a?String
         available_methods = available_methods.split(/,.?/).map{|i| i.to_sym}
       else
         if not available_methods.is_a?Array
           raise 'Only Array or String of comma separated values are allowed'
         end
       end

       assign_methods = available_methods & all.map { |p_m| p_m.id.to_sym }

       SystemConfiguration::Variable.set_value('payments.available_methods', 
            assign_methods.join(', ')) unless assign_methods.empty?

     end

     #
     # Create a charge using the payment method
     #
     def charge(opts)

       amount = opts[:amount]
       currency = opts[:currency]

     end

     private

     def self.payment_methods
       @defined_payment_methods ||= []
     end

  end

end