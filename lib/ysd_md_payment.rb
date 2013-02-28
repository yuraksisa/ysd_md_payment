require 'r18n-desktop'
R18n.from_env('./i18n')

require 'payments/ysd_md_payment_method'
require 'payments/ysd_md_gateway_payment_method'
require 'payments/ysd_md_offline_payment_method'
require 'payments/ysd_md_pm_cecabank'
require 'payments/ysd_md_pm_bank_transfer'

