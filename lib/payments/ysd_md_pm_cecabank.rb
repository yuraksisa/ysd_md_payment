require 'tilt' unless defined?Tilt
require 'digest/sha1' unless defined? Digest::SHA1
require 'r18n-core'

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
    def charge_form(charge={})
    
      num_operacion = charge[:reference]
      importe = charge[:amount]

      result = <<-EOF 
        <form action="<%=ceca_url%>" method="POST" 
              enctype="application/x-www-form-urlencoded">
          <input name="MerchantId" type="hidden" value="<%=merchant_id%>"/>
          <input name="AcquirerId" type="hidden" value="<%=acquirer_id%>"/>
          <input name="TerminalId" type="hidden" value="<%=terminal_id%>"/>
          <input name="URL_OK" type="hidden" value="<%=url_ok%>"/>
          <input name="URL_NOK" type="hidden" value="<%=url_nok%>"/>
          <input name="Firma" type="hidden" 
                 value="<%=firma(num_operacion, importe)%>"/>
          <input name="Cifrado" type="hidden" value="SHA1"/>        
          <input name="Num_operacion" type="hidden" value="<%=num_operacion%>">
          <input name="Importe" value="<%=format_amount(importe)%>">
          <input name="TipoMoneda" value="978"/>
          <input name="Exponente" value="2"/>
          <input name="Pago_soportado" value="SSL"/>
          <input name="Idioma" value="1"/>
        </form>
      EOF

      template = Tilt.new('erb'){result}
      template.render(self, {:num_operacion => num_operacion, 
      	                     :importe => importe})      

    end

    private

    def ceca_url
       "http://tpv.ceca.es:8000/cgi-bin/tpv"
    end

    def merchant_id
      "123456789"
    end

    def acquirer_id
      "1234567890"
    end

    def terminal_id
      "12345678"
    end
    
    def clave_encriptacion
       "12345678"
    end

    def url_ok
      "http://localhost:5000/ok"
    end

    def url_nok
      "http://localhost:5000/nok"
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