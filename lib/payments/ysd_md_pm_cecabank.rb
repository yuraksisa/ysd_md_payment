require 'tilt' unless defined?Tilt
require 'digest/sha1' unless defined? Digest::SHA1

#
# It represents the CECABANK payment
#
module Payments

  #
  # The concrete cecabank payment
  #
  module CecaBankPayment

    #
    # Implementation
    #
    # @param [Hash] The charge information
    #
    # @return [String] The form to post to the gateway
    #
    def charge_form(charge, opts)
    
      result = <<-EOF 
        <html>
        <body>
        <form action="<%=ceca_url%>" method="POST" 
              enctype="application/x-www-form-urlencoded"
              name="gateway">
          <input name="MerchantID" type="hidden" value="<%=merchant_id%>"/>
          <input name="AcquirerBIN" type="hidden" value="<%=acquirer_id%>"/>
          <input name="TerminalID" type="hidden" value="<%=terminal_id%>"/>
          <input name="URL_OK" type="hidden" value="<%=url_ok%>"/>
          <input name="URL_NOK" type="hidden" value="<%=url_nok%>"/>
          <input name="Firma" type="hidden" 
                 value="<%=firma(num_operacion, format_amount(importe))%>"/>
          <input name="Cifrado" type="hidden" value="SHA2"/>        
          <input name="Num_operacion" type="hidden" value="<%=num_operacion%>">
          <input name="Importe" type="hidden" value="<%=format_amount(importe)%>">
          <input name="TipoMoneda" type="hidden" value="978"/>
          <input name="Exponente" type="hidden" value="2"/>
          <input name="Pago_soportado" type="hidden" value="SSL"/>
          <input name="Idioma" type="hidden" value="1"/>
        </form>
        <script type="text/javascript">
          document.forms["gateway"].submit();
        </script>
        </body>
        </html>
      EOF

      template = Tilt.new('erb'){result}
      template.render(self, {:num_operacion => charge.id.to_s,
      	                     :importe => charge.amount})      

    end

    #
    # Calculate the signature notification from its parameters
    #
    def notification_signature(ns_merchant_id, 
                               ns_acquirer_bin,
                               ns_terminal_id, 
                               ns_num_operacion, 
                               ns_importe, 
                               ns_tipo_moneda,
                               ns_exponente,
                               ns_referencia)

      signature = ""
      signature << clave_encriptacion
      signature << ns_merchant_id
      signature << ns_acquirer_bin
      signature << ns_terminal_id
      signature << ns_num_operacion
      signature << ns_importe
      signature << ns_tipo_moneda
      signature << ns_referencia

      p "calculating notification signature: #{signature}"

      Digest::SHA256.hexdigest signature

    end

    private

    #
    # Firma
    #
    # @return [String]
    #
    def firma(num_operacion, importe)

      signature = ""
      signature << clave_encriptacion
      signature << merchant_id
      signature << acquirer_id
      signature << terminal_id
      signature << num_operacion
      signature << importe
      signature << '978'
      signature << '2'
      signature << 'SHA2'
      signature << url_ok
      signature << url_nok

      p "calculating signature: #{signature}"

      Digest::SHA256.hexdigest signature

    end

    #
    # Format the amount to send it
    #
    def format_amount(amount)
      ("%.2f" % amount).gsub('.','').rjust(12,'0')
    end

    def ceca_url
      SystemConfiguration::SecureVariable.get_value('payments.cecabank.url')
    end

    def merchant_id
      SystemConfiguration::SecureVariable.get_value('payments.cecabank.merchant_id')
    end

    def acquirer_id
      SystemConfiguration::SecureVariable.get_value('payments.cecabank.acquirer_id')
    end

    def terminal_id
      SystemConfiguration::SecureVariable.get_value('payments.cecabank.terminal_id')
    end
    
    def clave_encriptacion
      SystemConfiguration::SecureVariable.get_value('payments.cecabank.clave_encriptacion')
    end

    def url_ok
      SystemConfiguration::SecureVariable.get_value('payments.cecabank.url_ok')
    end

    def url_nok
      SystemConfiguration::SecureVariable.get_value('payments.cecabank.url_nok')
    end

  end
  
  cecabank = GatewayPaymentMethod.new(:cecabank,
    :title => lambda{Payments.r18n.t.cecabank.title},
    :description => lambda{Payments.r18n.t.cecabank.description},
    :icon => 'http://www.credit-card-logos.com/images/multiple_credit-card-logos-1/credit_card_logos_3.gif') 

  cecabank.extend CecaBankPayment  

end