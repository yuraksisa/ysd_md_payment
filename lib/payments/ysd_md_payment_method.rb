require 'json' unless defined?JSON
require 'ysd_md_configuration' unless defined?System::Variable
require 'ysd_md_translation' unless defined?Yito::Translation

module Payments
 
  extend Yito::Translation::ModelR18

  def self.r18n
    
    check_r18n!(:payments_r18n, File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'i18n')))

  end

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
     
     attr_accessor :id, :icon, :opts
   
     def initialize(id, opts={})
       @id = id
       @title = opts.delete(:title)
       @description = opts.delete(:description)
       @icon = opts.delete(:icon)
       @opts = opts
       PaymentMethod.payment_methods << self
     end

     def title
       if @title.is_a?Proc
         @title.call
       else
         @title
       end
     end

     def description
       if @description.is_a?Proc
         @description.call
       else
         @description
       end
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

       av_payment_methods = SystemConfiguration::Variable.
         get_value('payments.available_methods').split(',').map{|item| item.to_sym}

       all.select do |payment_method|
       	  av_payment_methods.include? payment_method.id
       end

     end

     #
     # Retrieve the payment methods available for the current application,
     # taking into account compatibilities
     #
     def self.available_to_web

       payment_methods = Payments::PaymentMethod.available
       paypal_payment_method = payment_methods.select { |payment_method| payment_method.id == :paypal_standard}
       payment_methods.keep_if { |payment_method| payment_method.id != :paypal_standard}
       paypal = (paypal_payment_method.size == 1)

       OpenStruct.new({tpv_virtual: payment_methods.first, paypal: paypal})

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

     def to_json(*args)
       {:id => id, :title => title, :description => description, :icon => icon}.to_json
     end

     private

     def self.payment_methods
       @defined_payment_methods ||= []
     end

  end

end