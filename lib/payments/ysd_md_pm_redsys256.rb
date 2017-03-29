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

    def charge_form(charge, opts)
    
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

      merchant_parameters = merchant_parameters(charge)
      firma = firma(merchant_parameters, charge.id)      

      template = Tilt.new('erb'){result}
      template.render(self, {:merchant_parameters => merchant_parameters, 
                             :firma => firma
                            })      

    end

    #
    # Merchant parameters
    #
    def merchant_parameters(charge)

      parameters = {}
      parameters.store("Ds_Merchant_Amount",format_amount(charge.amount))
      parameters.store("Ds_Merchant_Currency", "978")
      parameters.store("Ds_Merchant_PayMethods", "C")
      parameters.store("Ds_Merchant_Order", format_num_operacion(charge.id))
      parameters.store("Ds_Merchant_MerchantCode", merchant_code)
      parameters.store("Ds_Merchant_Terminal", terminal_id)
      parameters.store("Ds_Merchant_TransactionType", "0")
      parameters.store("Ds_Merchant_MerchantURL", notify_url)
      parameters.store("Ds_Merchant_UrlOK", return_url_ok)
      parameters.store("Ds_Merchant_UrlKO", return_url_cancel)
      parameters_json = parameters.to_json
      
      Base64.strict_encode64(parameters_json)

    end

    #
    # Firma
    #
    # @return [String] 
    #
    def firma(merchant_parameters, charge_id)

      key = Base64.decode64(clave_encriptacion)
      
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

    def redsys_url
      SystemConfiguration::SecureVariable.get_value('payments.redsys.url')
    end

    def merchant_code
      SystemConfiguration::SecureVariable.get_value('payments.redsys.merchant_code')
    end

    def terminal_id
      SystemConfiguration::SecureVariable.get_value('payments.redsys.terminal_id')
    end
    
    def clave_encriptacion
      SystemConfiguration::SecureVariable.get_value('payments.redsys.clave_encriptacion')
    end

    def return_url_ok
      # In case of detached front-end there are two domains (front-end and backoffice) 
      return_site_url = SystemConfiguration::Variable.get_value("payments.return_site_url", nil)
      if !return_site_url.nil? && !return_site_url.empty?
        return_site_url
      else  
        site_domain = SystemConfiguration::Variable.get_value("site.domain")
        "#{site_domain}/charge-return/redsys256"
      end  
    end

    def return_url_cancel
       # In case of detached front-end there are two domains (front-end and backoffice) 
      return_site_url = SystemConfiguration::Variable.get_value("payments.return_site_url", nil)
      if !return_site_url.nil? && !return_site_url.empty?
        return_site_url
      else  
        site_domain = SystemConfiguration::Variable.get_value("site.domain")
        "#{site_domain}/charge-return/redsys256/cancel"
      end
    end

    def notify_url
       site_domain = SystemConfiguration::Variable.get_value("site.domain")
       "#{site_domain}/charge-processed/redsys256"       
    end


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