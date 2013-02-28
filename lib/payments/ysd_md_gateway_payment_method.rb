module Payments
  
  # 
  # Gateway payment
  #
  # The system does not hold the credit card information. This is done by the 
  # bank.
  #
  # An browser interaction with the entity is needed in order to make the
  # charge. A form is sent to the bank, and the response is managed by the
  # system.
  #
  # We have support for the current gateways:
  #
  #  * cecabank [see ysd_md_pm_cecabank]
  #
  #     It the payment gateway for spanish "Cajas de Ahorro" 
  #
  #  * sermepa [in progress]
  #
  #     It's the payment gateway for la Caixa, Banco Santander, BBVA, Banc 
  #     Sabadell
  #
  #  * paypal [in progress]  
  #
  # This type of payment offer the following methods to connect to the bank
  # gateway :
  #
  # Usage:
  #
  #   (Note: my_gateway has been defined)
  #
  #   ## Get the payment method
  #
  #   my_gateway = Payments::PaymentMethod.get(:my_gateway)
  #
  #   ## Create a charge
  #
  #   charge = my_gateway.charge({:amount => 150.00, :currency => 'EUR'})
  #
  #   ## Get the charge form to send to the bank gateway
  #
  #   charge_form = my_gateway.charge_form(charge)
  #
  #
  class GatewayPaymentMethod < PaymentMethod

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