require 'ysd_md_payment'
require 'data_mapper' unless defined?DataMapper

module DataMapper
  class Transaction
  	module SqliteAdapter
      def supports_savepoints?
        true
      end
  	end
  end
end

#
# Reopen the charge class to add the charge source relationship
#
module Payments
  #
  # It represents a charge source for testing purpose
  #
  class Order
    include DataMapper::Resource
    storage_names[:default] = 'payment_orders'
    property :id, Serial
    property :description, String
    belongs_to :charge, 'Payments::Charge', :child_key => [:charge_id], :parent_key => [:id]
    def charge_detail=(opts={})
      @charge_detail= opts
    end
    def charge_detail
      unless instance_variable_defined?("@charge_detail")
        return []
      else
        return @charge_detail
      end
    end
  end

  class Charge
    has 1, :order_charge_source, 'Payments::Order'
  end
end

DataMapper::Logger.new(STDOUT, :debug)
DataMapper.setup :default, "sqlite3::memory:"
DataMapper::Model.raise_on_save_failure = true
DataMapper.finalize 

DataMapper.auto_migrate!