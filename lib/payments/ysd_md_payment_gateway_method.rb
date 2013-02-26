module Payments
  #
  # It's a payment gateway method, that is a payment method that uses a 
  # gateway to make the charge
  #
  class PaymentGatewayMethod < PaymentMethod
    
    #
    # Get the form to do the POST to the gateway
    #
    # @param [Hash] The charge information
    #
    # @return [String] The form to post to the gateway
    #
    #
    def charge_form(charge={})
      raise "This method has to be defined on the concrete implementations"
    end

  end
end