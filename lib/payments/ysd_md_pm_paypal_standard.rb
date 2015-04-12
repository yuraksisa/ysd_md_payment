require 'tilt' unless defined?Tilt

module Payments

  #
  # It represents the paypal standard payment method
  #
  module PaypalStandardPayment

  	def charge_form(charge, opts)

      result = <<-EOF
        <html>
        <body>
        <form action="#{paypal_standard_url}" method="POST" name="gateway"/>
          <input type="hidden" name="cmd" value="_xclick"/>
          <input type="hidden" name="invoice" value="<%=num_operacion%>"/>
          <input type="hidden" name="currency_code" value="<%=currency%>"/>
          <input type="hidden" name="amount" value="<%=amount%>"/>
          <input type="hidden" name="item_name" value="<%=item_name%>"/>
          <input type="hidden" name="business" value="<%=paypal_standard_business%>"/>
          <input type="hidden" name="return" value="<%=url_ok%>"/>
          <input type="hidden" name="cancel_return" value="<%=url_return%>"/>
          <input type="hidden" name="notify_url" value="<%=url_notify%>"/>
          <input type="hidden" name="no_shipping" value="1"/>
        </form>
        <script type="text/javascript">
          document.forms["gateway"].submit();
        </script>        
        </body>
        </html>
      EOF

      item_name = (charge.detail.size > 0 and charge.detail.first.has_key?(:item_description)) ? charge.detail.first[:item_description] : ""
      
      template = Tilt.new('erb'){result}
      template.render(self, {:num_operacion => format_num_operacin(charge.id), 
      	                     :currency => charge.currency,
      	                     :amount => format_amount(charge.amount),
      	                     :item_name => item_name,
      	                     :url_ok => return_url_ok,
      	                     :url_return =>  return_url_cancel,
      	                     :url_notify => notify_url
      	                    })      

  	end
  
    def format_amount(amount)
      ("%.2f" % amount)
    end

    def return_url_ok
       site_domain = SystemConfiguration::Variable.get_value("site.domain")
    	"#{site_domain}/charge-return/paypal-standard"
    end

    def return_url_cancel
       site_domain = SystemConfiguration::Variable.get_value("site.domain")
       "#{site_domain}/charge-return/paypal-standard/cancel"
    end

    def notify_url
       site_domain = SystemConfiguration::Variable.get_value("site.domain")
       "#{site_domain}/charge-processed/paypal-standard"       
    end

    def paypal_standard_url
      paypal_base = SystemConfiguration::SecureVariable.get_value('payments.paypal_standard.url')
      "#{paypal_base}/cgi-bin/webscr"
    end

    def paypal_standard_business
      SystemConfiguration::SecureVariable.get_value('payments.paypal_standard.business_email')
    end

  end

  paypal_standard = GatewayPaymentMethod.new(:paypal_standard,
    :title => lambda{ Payments.r18n.t.paypal_standard.title},
    :description => lambda{Payments.r18n.t.paypal_standard.description},
    :icon => 'https://www.paypalobjects.com/webstatic/mktg/logo-center/logotipo_paypal_tarjetas.jpg')
  paypal_standard.extend PaypalStandardPayment

end