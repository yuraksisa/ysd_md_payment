require 'ysd_md_configuration' unless defined?System::Variable

module Payments
  
  # Instances of this class represent payment method.
  #
  # Usage:
  #   
  #   Payments::PaymentMethod.available= [:paypal, :cecabank]
  #   Payments::PaymentMethod.
  #
  #
  class PaymentMethod
     
     attr_accessor :id, :title, :description
   
     def initialize(id, opts={})
       @id = id
       @title = opts[:title]
       @description = opts[:description]
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

     private

     def self.payment_methods
       @defined_payment_methods ||= []
     end

  end

end