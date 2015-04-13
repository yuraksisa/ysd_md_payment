require 'tilt' unless defined?Tilt
require 'digest/sha1' unless defined? Digest::SHA1

#
# It represents the CECABANK payment
#
module Payments

  #
  # The concrete redsys payment
  #
  module RedsysPayment

    def charge_form(charge, opts)
    
      result = <<-EOF 
        <html>
        <body>
        <form action="<%=redsys_url%>" method="POST" 
              enctype="application/x-www-form-urlencoded"
              name="gateway">
          <input name="Ds_Merchant_Amount" type="hidden" value="<%=amount%>"/>
          <input name="Ds_Merchant_Currency" type="hidden" value="978"/>
          <input name="Ds_Merchant_Order" type="hidden" value="<%=num_operacion%>"/>
          <input name="Ds_Merchant_MerchantCode" type="hidden" value="<%=merchant_code%>"/>
          <input name="Ds_Merchant_Terminal" type="hidden" value="<%=terminal_id%>"/>
          <input name="Ds_Merchant_TransactionType" type="hidden" value="0"/>
          <input name="Ds_Merchant_MerchantURL" type="hidden" value="<%=notify_url%>"/>        
          <input name="Ds_Merchant_UrlOK" type="hidden" value="<%=return_url_ok%>"/>
          <input name="Ds_Merchant_UrlKO" type="hidden" value="<%=return_url_cancel%>"/>
          <input name="Ds_Merchant_MerchantSignature" type="hidden" value="<%=firma%>"/>
        </form>
        <script type="text/javascript">
          document.forms["gateway"].submit();
        </script>
        </body>
        </html>
      EOF

      template = Tilt.new('erb'){result}
      template.render(self, {:num_operacion => format_num_operacion(charge.id), 
                             :amount => format_amount(charge.amount),
                             :firma => firma(format_num_operacion(charge.id), format_amount(charge.amount))
                            })      

    end

    def calculate_response_signature(num_operation, amount, response_code, currency, merchant_id)
      texto = ""
      texto << amount
      texto << num_operation
      texto << merchant_id
      texto << currency
      texto << response_code
      texto << clave_encriptacion
      Digest::SHA1.hexdigest(texto).upcase
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
       site_domain = SystemConfiguration::Variable.get_value("site.domain")
      "#{site_domain}/charge-return/redsys"
    end

    def return_url_cancel
       site_domain = SystemConfiguration::Variable.get_value("site.domain")
       "#{site_domain}/charge-return/redsys/cancel"
    end

    def notify_url
       site_domain = SystemConfiguration::Variable.get_value("site.domain")
       "#{site_domain}/charge-processed/redsys"       
    end

    #
    # Firma
    #
    # @return [String] 
    #
    def firma(num_operacion, importe)
      texto = ""
      texto << importe
      texto << num_operacion
      texto << merchant_code
      texto << '978'
      texto << '0'
      texto << notify_url
      texto << clave_encriptacion
      Digest::SHA1.hexdigest(texto).upcase
    end

    def format_num_operacion(num_operacion)
      num_operacion.to_s.rjust(12,'0')    
    end

    def format_amount(amount)
      ("%.2f" % amount).gsub('.','')
    end

  end
  
  redsys = GatewayPaymentMethod.new(:redsys,
    :title => lambda{Payments.r18n.t.redsys.title},
    :description => lambda{Payments.r18n.t.redsys.description},
    :icon => 'http://www.credit-card-logos.com/images/multiple_credit-card-logos-1/credit_card_logos_3.gif') 

  redsys.extend RedsysPayment  

end