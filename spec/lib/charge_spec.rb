require 'spec_helper'

describe Payments::Charge do 

  let (:simple_charge) { {:amount => 100, 
       :currency => 'EUR', 
  	   :payment_method_id => :cecabank} }

  describe ".create" do

    context "valid" do
    
      subject { Payments::Charge.create(simple_charge) }
    
      its(:id) { should_not be_nil }
      its(:new?) { should be_false }
      its(:date) { should_not be_nil }
      its(:payment_method) { should be_an_instance_of(Payments::GatewayPaymentMethod)}
      its(:status) { should == :pending }
    
    end

    context "invalid status" do

      it "raises DataMapper::SaveFailureError" do
        expect { Payments::Charge.create({:amount => 50, 
          :currency => 'EUR', 
          :payment_method_id => :cecabank,
          :status => :invalid_status})}.to raise_error(DataMapper::SaveFailureError)
      end

    end

  end
	
end