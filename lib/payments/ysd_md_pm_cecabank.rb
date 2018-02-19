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

    CECABANK_URL_PRODUCTION_URL = "https://pgw.ceca.es/cgi-bin/tpv"
    CECABANK_URL_TEST_URL = "http://tpv.ceca.es:8000"

    #
    # Get the configuration
    #
    def configuration(sales_channel_code=nil)

      sales_channel_payment = ::Yito::Model::SalesChannel::SalesChannelPayment.first('sales_channel.code' => sales_channel_code) unless sales_channel_code.nil?

      # Check if use the default payment configuration or the sales_channel's one
      default_payment_configuration = (sales_channel_code.nil? or sales_channel_payment.nil? or (!sales_channel_payment.nil? and sales_channel_payment.override_payment))

      # Set up cecabank gateway variables (ceca_url, merchant_id, acquirer_id, terminal_id, clave_encriptacion, url_ok, url_nok)
      # cecabank notification url is setup in the platform back-office
      environment_variable = default_payment_configuration ? 'payments.cecabank.environment' : "payments.cecabank.environment_sc_#{sales_channel_code}"
      merchant_id_variable = default_payment_configuration ? 'payments.cecabank.merchant_id' : "payments.cecabank.merchant_id_sc_#{sales_channel_code}"
      acquirer_id_variable = default_payment_configuration ? 'payments.cecabank.acquirer_id' : "payments.cecabank.acquirer_id_sc_#{sales_channel_code}"
      terminal_id_variable = default_payment_configuration ? 'payments.cecabank.terminal_id' : "payments.cecabank.terminal_id_sc_#{sales_channel_code}"
      clave_encriptacion_variable = default_payment_configuration ? 'payments.cecabank.clave_encriptacion' : "payments.cecabank.clave_encriptacion_sc_#{sales_channel_code}"
      url_ok_variable = default_payment_configuration ? 'payments.cecabank.url_ok' : "payments.cecabank.url_ok_sc_#{sales_channel_code}"
      url_nok_variable = default_payment_configuration ? 'payments.cecabank.url_nok' : "payments.cecabank.url_nok_sc_#{sales_channel_code}"

      # Build the configuration
      {ceca_url: SystemConfiguration::SecureVariable.get_value(environment_variable) == 'production' ? CECABANK_URL_PRODUCTION_URL : CECABANK_URL_TEST_URL,
       merchant_id: SystemConfiguration::SecureVariable.get_value(merchant_id_variable),
       acquirer_id: SystemConfiguration::SecureVariable.get_value(acquirer_id_variable),
       terminal_id: SystemConfiguration::SecureVariable.get_value(terminal_id_variable),
       clave_encriptacion: SystemConfiguration::SecureVariable.get_value(clave_encriptacion_variable),
       url_ok: SystemConfiguration::SecureVariable.get_value(url_ok_variable),
       url_nok: SystemConfiguration::SecureVariable.get_value(url_nok_variable)}

    end

    #
    # Implementation
    #
    # @param [Hash] The charge information
    #
    # @return [String] The form to post to the gateway
    #
    def charge_form(charge, opts)

      gateway_configuration = configuration(charge.sales_channel_code)

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
      template.render(self, {num_operacion: charge.id.to_s,
      	                     importe: charge.amount,
                             ceca_url: gateway_configuration[:ceca_url],
                             merchant_id: gateway_configuration[:merchant_id],
                             acquirer_id: gateway_configuration[:acquirer_id],
                             terminal_id: gateway_configuration[:terminal_id],
                             url_ok: gateway_configuration[:url_ok],
                             url_nok: gateway_configuration[:url_nok],
                            })

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
      signature << ns_exponente
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

    #def ceca_environment
    #  SystemConfiguration::SecureVariable.get_value('payments.cecabank.environment')
    #end

    #def ceca_url
    #  SystemConfiguration::SecureVariable.get_value('payments.cecabank.url')
    #end

    #def merchant_id
    #  SystemConfiguration::SecureVariable.get_value('payments.cecabank.merchant_id')
    #end

    #def acquirer_id
    #  SystemConfiguration::SecureVariable.get_value('payments.cecabank.acquirer_id')
    #end

    #def terminal_id
    #  SystemConfiguration::SecureVariable.get_value('payments.cecabank.terminal_id')
    #end
    
    #def clave_encriptacion
    #  SystemConfiguration::SecureVariable.get_value('payments.cecabank.clave_encriptacion')
    #end

    #def url_ok
    #  SystemConfiguration::SecureVariable.get_value('payments.cecabank.url_ok')
    #end

    #def url_nok
    #  SystemConfiguration::SecureVariable.get_value('payments.cecabank.url_nok')
    #end

  end
  
  cecabank = GatewayPaymentMethod.new(:cecabank,
    :title => lambda{Payments.r18n.t.cecabank.title},
    :description => lambda{Payments.r18n.t.cecabank.description},
    :icon => 'http://www.credit-card-logos.com/images/multiple_credit-card-logos-1/credit_card_logos_3.gif') 

  cecabank.extend CecaBankPayment  

end