require 'ysd_md_configuration' unless defined?SystemConfiguration::SecureVariable

module Payments
 
 module BankTransfer

   def description
     super %  {:bank_name => bank_name, :account_number => account_number}
   end

   def bank_name
     SystemConfiguration::SecureVariable.get_value('payments.bank_transfer.bank_name')
   end

   def account_number
     SystemConfiguration::SecureVariable.get_value('payments.bank_transfer.account')
   end

 end

 bank_transfer = OfflinePaymentMethod.new(:bank_transfer,
   :title => lambda{Payments.r18n.t.bank_transfer.title},
   :description => lambda{Payments.r18n.t.bank_transfer.description})

 bank_transfer.extend BankTransfer

end