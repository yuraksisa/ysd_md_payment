require 'tilt' unless defined?Tilt

module Payments
  #
  # It represents the Pasat Internet 4B payment
  #
  module PI4BPayment
    
    #
    # Defines the charge form used to start the process
    #
    def charge_form(charge, opts={})

      result = <<-EOF
        <html>
        <body>
        <form action="#{pi4b_url}" method="POST" name="gateway">
          <input type="hidden" name="order" value="#{charge.id}">
          <input type="hidden" name="store" value="#{merchant_id}">
          <input type="hidden" name="lang" value="#{opts[:language]||'es'}">
        </form>
        <script type="text/javascript">
          document.forms["gateway"].submit();
        </script>
        </body>
        </html>
      EOF
      
    end

    #
    # Define the response when the payment gateway request information
    #
    # @param [Hash] parameters
    #
    def charge_detail(opts={})
      
      merchant_id = opts[:merchant_id]
      charge_id   = opts[:charge_id]

      if charge_id and charge = Payments::Charge.get(charge_id)
        result = []
        result << "M978#{format_amount(charge.amount)}"
        result << charge.detail.size
        charge.detail.each do |charge_detail|
          result << charge_detail[:item_reference]
          result << charge_detail[:item_description]
          result << charge_detail[:item_units]
          result << format_amount(charge_detail[:item_price])
        end
        result.join('\r\n')
      else
        nil
      end

    end

    def merchant_id
      SystemConfiguration::SecureVariable.get_value('payments.pi4b.merchant_id')
    end
 
    def pi4b_url
      SystemConfiguration::SecureVariable.get_value('payments.pi4b.url')
    end

    def format_amount(amount)
      ("%.2f" % amount).gsub('.','')
    end

  end


  pi4b = GatewayPaymentMethod.new(:pi4b,
    :title => lambda{ Payments.r18n.t.pi4b.title},
    :description => lambda{Payments.r18n.t.pi4b.description},
    :icon => 'http://www.credit-card-logos.com/images/multiple_credit-card-logos-1/credit_card_logos_3.gif')
  pi4b.extend PI4BPayment
  

end