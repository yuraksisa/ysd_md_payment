module Payments
 
 module BankTransfer

   def description
     super %  {:bank_name => bank_name, :account_number => account_number}
   end

   private

   def bank_name
     "La Caixa"
   end

   def account_number
     "1234-5678-90-1234567890"
   end

 end

 bank_transfer = OfflinePaymentMethod.new(:bank_transfer,
   :title => Payments.r18n.t.bank_transfer.title,
   :description => Payments.r18n.t.bank_transfer.description)

 bank_transfer.extend BankTransfer

end