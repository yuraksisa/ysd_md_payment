require 'tilt' unless defined?Tilt
require 'openssl' unless defined?OpenSSL

#
# It represents the CECABANK payment
#
module Payments

  #
  # The concrete redsys payment
  #
  module Redsys256Payment

    REDSYS256_URL_PRODUCTION_URL = "https://sis.redsys.es/sis/realizarPago"
    REDSYS256_URL_TEST_URL = "https://sis-t.sermepa.es:25443/sis/realizarPago"

    #
    # Get the configuration
    #
    def configuration(sales_channel_code=nil)

      sales_channel_payment = ::Yito::Model::SalesChannel::SalesChannelPayment.first('sales_channel.code' => sales_channel_code) unless sales_channel_code.nil?

      # Check if use the default payment configuration or the sales_channel's one
      default_payment_configuration = (sales_channel_code.nil? or sales_channel_payment.nil? or (!sales_channel_payment.nil? and !sales_channel_payment.override_payment))

      # Set up redsys256 gateway variables (redsys_url, merchant_code, terminal_id, clave_encriptacion)
      environment_variable = default_payment_configuration ? 'payments.redsys.environment' : "payments.redsys.environment_sc_#{sales_channel_code}"
      redsys_url = SystemConfiguration::SecureVariable.get_value(environment_variable) == 'production' ? REDSYS256_URL_PRODUCTION_URL : REDSYS256_URL_TEST_URL
      merchant_code_variable = default_payment_configuration ? 'payments.redsys.merchant_code' : "payments.redsys.merchant_code_sc_#{sales_channel_code}"
      terminal_id_variable = default_payment_configuration ? 'payments.redsys.terminal_id' : "payments.redsys.terminal_id_sc_#{sales_channel_code}"
      clave_encriptacion_variable = default_payment_configuration ? 'payments.redsys.clave_encriptacion' : "payments.redsys.clave_encriptacion_sc_#{sales_channel_code}"

      # Set up return_url_ok, return_url_cancel and notify_url
      #
      # return_url_ok : The return url in case the payment is done [front-end]
      # return_url_cancel: The return url in case the payment is canceled [front-end]
      # notify_url: The url to notify of the operation
      #
      # If the front-end is detached from the back-end the system allows to setup a variable to register to url to return to
      # after the process. It's [payments.return_site_url] or [payments.return_site_url_sc_{sales_channel_code}]
      #
      #
      site_domain = SystemConfiguration::Variable.get_value("site.domain")
      return_site_url_variable = default_payment_configuration ? 'payments.return_site_url' : "payments.return_site_url_sc_#{sales_channel_code}"
      return_site_url = SystemConfiguration::Variable.get_value(return_site_url_variable, nil)
      if !return_site_url.nil? and !return_site_url.empty?
        return_url_ok = return_url_cancel = return_site_url
      else
        return_url_ok = "#{site_domain}/charge-return/redsys256"
        return_url_cancel = "#{site_domain}/charge-return/redsys256/cancel"
      end
      notify_url = "#{site_domain}/charge-processed/redsys256"

      # Build the configuration
      {redsys_url: redsys_url,
       merchant_code: SystemConfiguration::SecureVariable.get_value(merchant_code_variable),
       terminal_id: SystemConfiguration::SecureVariable.get_value(terminal_id_variable),
       clave_encriptacion: SystemConfiguration::SecureVariable.get_value(clave_encriptacion_variable),
       return_url_ok: return_url_ok,
       return_url_cancel: return_url_cancel,
       notify_url: notify_url}

    end

    def charge_form(charge, opts)

      gateway_configuration = configuration(charge.sales_channel_code)

      result = <<-EOF 
        <html>
        <body>
        <form action="<%=redsys_url%>" method="POST" 
              enctype="application/x-www-form-urlencoded"
              name="gateway">
          <input name="Ds_SignatureVersion" type="hidden" value="HMAC_SHA256_V1"/>
          <input name="Ds_MerchantParameters" type="hidden" value="<%=merchant_parameters%>"/>
          <input name="Ds_Signature" type="hidden" value="<%=firma%>"/>
        </form>
        <script type="text/javascript">
          document.forms["gateway"].submit();
        </script>
        </body>
        </html>
      EOF

      merchant_parameters = merchant_parameters(charge, gateway_configuration)
      firma = firma(merchant_parameters, charge.id)      

      template = Tilt.new('erb'){result}
      template.render(self, {redsys_url: gateway_configuration[:redsys_url],
                             merchant_parameters: merchant_parameters,
                             firma: firma
                            })      

    end

    #
    # Merchant parameters
    #
    def merchant_parameters(charge, gateway_configuration)

      parameters = {}
      parameters.store("Ds_Merchant_Amount",format_amount(charge.amount))
      parameters.store("Ds_Merchant_Currency", "978")
      parameters.store("Ds_Merchant_PayMethods", "C")
      parameters.store("Ds_Merchant_Order", format_num_operacion(charge.id))
      parameters.store("Ds_Merchant_MerchantCode", gateway_configuration[:merchant_code])
      parameters.store("Ds_Merchant_Terminal", gateway_configuration[:terminal_id])
      parameters.store("Ds_Merchant_TransactionType", "0")
      parameters.store("Ds_Merchant_MerchantURL", gateway_configuration[:notify_url])
      parameters.store("Ds_Merchant_UrlOK", gateway_configuration[:return_url_ok])
      parameters.store("Ds_Merchant_UrlKO", gateway_configuration[:return_url_cancel])
      parameters_json = parameters.to_json
      
      Base64.strict_encode64(parameters_json)

    end

    #
    # Firma
    #
    # @return [String] 
    #
    def firma(merchant_parameters, charge_id)

      charge = Payments::Charge.get(charge_id)
      gateway_configuration = configuration(charge.sales_channel_code)

      key = Base64.decode64(gateway_configuration[:clave_encriptacion])
      
      # Adjust the key of 3DES algorith to be multiple of 8
      num_operacion = format_num_operacion(charge_id)
      if (num_operacion.bytesize % 8) > 0
        num_operacion += "\0" * (8 - num_operacion.bytesize % 8)
      end

      # mcrypt_encrypt(MCRYPT_3DES, $key, $message, MCRYPT_MODE_CBC, $iv); 
      #
      # Attention: 
      #   - it's not necessary to assign iv (default value is enough)
      #   - it's not necessary to appen cipher.final to cipher.update
      #
      cipher = OpenSSL::Cipher.new('des-ede3-cbc') # #des-ede3-cbc
      cipher.encrypt
      cipher.key = key
      ds_key = cipher.update(num_operacion) # DO NOT INCLUDE cipher.final

      # hash_hmac('sha256', $ent, $key, true);
      hash = OpenSSL::HMAC.digest('sha256', ds_key, merchant_parameters)
      Base64.strict_encode64(hash)

    end

    def decode_merchant_parameters(ds_merchant_parameters)

      JSON.parse(Base64.decode64(ds_merchant_parameters.tr("-_", "+/")))
      
    end

    private

    def format_num_operacion(num_operacion)
      num_operacion.to_s.rjust(12,'0')
    end

    def format_amount(amount)
      ("%.2f" % amount).gsub('.','')
    end

  end
  
  redsys256 = GatewayPaymentMethod.new(:redsys256,
    :title => lambda{Payments.r18n.t.redsys256.title},
    :description => lambda{Payments.r18n.t.redsys256.description},
    :icon => 'http://www.credit-card-logos.com/images/multiple_credit-card-logos-1/credit_card_logos_3.gif') 

  redsys256.extend Redsys256Payment  

end