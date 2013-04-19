require 'spec_helper'

describe Payments::Charge do 

  let (:simple_charge) { {:amount => 100, :currency => 'EUR', 
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

  describe ".charge_source" do

    context "charge with source" do

      subject { Payments::Order.create({:description => 'order charge 1234'}.merge({:charge => simple_charge})).charge }
      its(:charge_source) { should_not be_nil }
      its(:charge_source) { should be_an_instance_of(Payments::Order) }
      its("charge_source.description") { should == 'order charge 1234' }
    
    end

    context "charge without source" do
      
      subject { Payments::Charge.create(simple_charge) }
      its (:charge_source) { should be_nil }

    end
    
  end
	
  describe ".detail" do

    context "charge with source and detail" do
      
      let(:order_detail) do [{:item_reference => '123456', 
          :item_description => 'DESCRIPTION',
          :item_units => 1,
          :item_price => 120}]
      end

      subject do
        order = Payments::Order.create({:description => 'order charge 1235'}.merge({:charge => simple_charge})) 
        order.charge_detail= order_detail
        order.charge
      end

      before :each do
        subject.charge_source.should_receive(:charge_detail).and_return(order_detail)
      end

      its(:detail) { should_not be_nil }
      its(:detail) { should be_an_instance_of(Array) }
      its(:detail) { should == order_detail}

    end

    context "charge with source but no detail" do

      subject { Payments::Order.create({:description => 'order charge 1236'}.merge({:charge => simple_charge})).charge }
      its(:charge_source) { should_not be_nil }
      its(:detail) { should == [] }

    end

    context "charge without source" do
      
      subject { Payments::Charge.create(simple_charge) }
      its(:detail) { should == [] }

    end

  end

end