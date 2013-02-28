module Payments

  #
  # The payment is done offline. The system doesn't make the charge. The user
  # makes it and then notify the system.
  #
  # We support the following offline payments:
  #
  # * Bank transfer (ysd_md_pm_bank_transfer)
  #
  class OfflinePaymentMethod < PaymentMethod

  end

end