require 'tilt' unless defined?Tilt
require 'openssl' unless defined?OpenSSL

#
# It represents the CECABANK payment
#
module Payments

  #
  # The concrete redsys payment
  #
  module SantanderPayment

    def charge_form(charge, opts)

      the_order_id = format_order_id(charge.id) 
      the_amount = format_amount(charge.amount)
      the_timestamp = timestamp
      the_currency = charge.currency
      the_signature = firma(the_timestamp,
                            id_cliente, 
                            the_order_id, 
                            the_amount, 
                            the_currency)
      the_return_url = return_url

      result = <<-EOF 
        <html>
        <body>
        <form action="<%=santander_4b_url%>" method="POST" 
              enctype="application/x-www-form-urlencoded"
              name="gateway">
          <input name="MERCHANT_ID" type="hidden" value="<%=id_cliente%>"/>
          <input name="ORDER_ID" type="hidden" value="<%=order_id%>"/>
          <input name="ACCOUNT" type="hidden" value="<%=nombre_cuenta%>"/>
          <input name="AMOUNT" type="hidden" value="<%=amount%>"/>
          <input name="CURRENCY" type="hidden" value="<%=currency%>"/>
          <input name="TIMESTAMP" type="hidden" value="<%=timestamp%>"/>
          <input name="SHA1HASH" type="hidden" value="<%=signature%>"/>
          <input name="AUTO_SETTLE_FLAG" type="hidden" value="1">
          <input name="MERCHANT_RESPONSE_URL" type="hidden" value="<%=return_url%>"/>
        </form>
        <script type="text/javascript">
          document.forms["gateway"].submit();
        </script>
        </body>
        </html>
      EOF
      
      template = Tilt.new('erb'){result}
      form_value = template.render(self, { 
                              :order_id => the_order_id,
                              :amount => the_amount,
                              :currency => the_currency,
                              :timestamp => the_timestamp,
                              :signature => the_signature,
                              :return_url => the_return_url,
                              :santander_4b_url => santander_4b_url
                            })       

      return form_value

    end

    def return_signature(timestamp, id_cliente, order_id, result, message, pasref, authcode)
      texto = ""
      texto << timestamp 
      texto << "."
      texto << id_cliente
      texto << "."
      texto << order_id
      texto << "."
      texto << result
      texto << "."
      texto << message
      texto << "."
      texto << pasref
      texto << "."
      texto << authcode
      texto = Digest::SHA1.hexdigest(texto).downcase
      texto << "."
      texto << secreto_compartido 
      Digest::SHA1.hexdigest(texto).downcase           
    end

    private

    #
    # Get the URL
    #
    def santander_4b_url
      environment = SystemConfiguration::SecureVariable.get_value('payments.santander.environment','test')
      if environment == 'production'
        SANTANDER_4B_PRODUCTION_URL
      else
        SANTANDER_4B_TEST_URL
      end
    end

    #
    # TPV configuration : id_cliente
    #
    def id_cliente
      SystemConfiguration::SecureVariable.get_value('payments.santander.id_cliente')
    end
    
    #
    # TPV configuration : nombre_cuenta
    #
    def nombre_cuenta
      SystemConfiguration::SecureVariable.get_value('payments.santander.nombre_cuenta')
    end

    #
    # TPV configuration : secreto_compartido
    #
    def secreto_compartido
      SystemConfiguration::SecureVariable.get_value('payments.santander.secreto_compartido')
    end      
    
    #
    # Return URL
    #
    def return_url
      site_domain = SystemConfiguration::Variable.get_value("site.domain")
      return "#{site_domain}/charge-return/santander"
    end

    # Format the order id
    #
    def format_order_id(num_operacion)
      num_operacion.to_s.rjust(12,'0')    
    end

    # Format the amount
    #
    def format_amount(amount)
      ("%.2f" % amount).gsub('.','')
    end    

    # Format the timestamp of the transaction
    #
    def timestamp
      DateTime.now.strftime("%Y%m%d%H%M%S")
    end    

    # Build the signature
    #
    def firma(timestamp, id_cliente, order_id, amount, currency)
      texto = ""
      texto << timestamp
      texto << "."
      texto << id_cliente
      texto << "."
      texto << order_id
      texto << "."
      texto << amount
      texto << "."
      texto << currency

      p "firma paso 1: #{texto}"

      texto = Digest::SHA1.hexdigest(texto).downcase
      texto << "."
      texto << secreto_compartido
      
      p "firma paso 2: #{texto}"

      Digest::SHA1.hexdigest(texto).downcase
    end


    SANTANDER_4B_TEST_URL = "https://hpp.prueba.santanderelavontpvvirtual.es/pay"
    SANTANDER_4B_PRODUCTION_URL = "https://hpp.santanderelavontpvvirtual.es/pay"

  end

  santander = GatewayPaymentMethod.new(:santander,
    :title => lambda{Payments.r18n.t.santander.title},
    :description => lambda{Payments.r18n.t.santander.description},
    :icon => 'http://www.credit-card-logos.com/images/multiple_credit-card-logos-1/credit_card_logos_3.gif') 

  santander.extend SantanderPayment  

end