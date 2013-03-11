require 'spec_helper'

describe Payments::Charge do 

  let (:simple_charge) { {:amount => 100, 
  	:currency => 'EUR', 
  	:payment_method => :ceca_bank} }

  context ".create" do

    subject { Payments::Charge.create(simple_charge) }
    
    its(:id) { should_not be_nil }
    its(:new?) { should be_false }
    its(:date) { should_not be_nil }

  end
	
end