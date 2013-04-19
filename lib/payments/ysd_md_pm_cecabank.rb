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
    def charge_form(charge)
    
      result = <<-EOF 
        <form action="<%=ceca_url%>" method="POST" 
              enctype="application/x-www-form-urlencoded"
              name="gateway">
          <input name="MerchantId" type="hidden" value="<%=merchant_id%>"/>
          <input name="AcquirerId" type="hidden" value="<%=acquirer_id%>"/>
          <input name="TerminalId" type="hidden" value="<%=terminal_id%>"/>
          <input name="URL_OK" type="hidden" value="<%=url_ok%>"/>
          <input name="URL_NOK" type="hidden" value="<%=url_nok%>"/>
          <input name="Firma" type="hidden" 
                 value="<%=firma(num_operacion, importe)%>"/>
          <input name="Cifrado" type="hidden" value="SHA1"/>        
          <input name="Num_operacion" type="hidden" value="<%=num_operacion%>">
          <input name="Importe" type="hidden" value="<%=format_amount(importe)%>">
          <input name="TipoMoneda" type="hidden" value="978"/>
          <input name="Exponente" type="hidden" value="2"/>
          <input name="Pago_soportado" type="hidden" value="SSL"/>
          <input name="Idioma" type="hidden" value="1"/>
        </form>
        <script type="text/javascript">
          window.onload = function() {
            document.forms['gateway'].submit();
          }
        </script>        
      EOF

      template = Tilt.new('erb'){result}
      template.render(self, {:num_operacion => charge.id, 
      	                     :importe => charge.amount})      

    end

    private

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

    #
    # Firma
    #
    # @return [String] 
    #
    def firma(num_operacion, importe)
      texto = ""
      texto << clave_encriptacion
      texto << merchant_id
      texto << acquirer_id
      texto << terminal_id
      texto << num_operacion
      texto << format_amount(importe)
      texto << '978'
      texto << '2'
      texto << 'SHA1'
      texto << url_ok
      texto << url_nok
      Digest::SHA1.hexdigest texto
    end

    def format_amount(amount)
      ("%.2f" % amount).gsub('.','')
    end

  end
  
  cecabank = GatewayPaymentMethod.new(:cecabank,
    :title => Payments.r18n.t.cecabank.title,
    :description => Payments.r18n.t.cecabank.description,
    :icon => 'http://www.credit-card-logos.com/images/multiple_credit-card-logos-1/credit_card_logos_3.gif') 

  cecabank.extend CecaBankPayment  

end