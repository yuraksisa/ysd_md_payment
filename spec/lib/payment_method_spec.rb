#encoding: utf-8
require 'spec_helper'

describe Payments::PaymentMethod do 
     
  before :all do   
   
    @test_payment_method = Payments::PaymentMethod.new(
      :test_payment_method, 
      :title => 'Test method', 
      :description => 'None') 

    @test_payment_method_2 = Payments::PaymentMethod.new(
      :test_payment_method_2, 
      :title => 'Test method 2', 
      :description => 'None 2') 

  end

  describe ".all" do # Retrieve all the payment methods
    
    subject { Payments::PaymentMethod.all }

    it { should be_an_instance_of(Array) }
    it { should include(@test_payment_method) }

  end

  describe ".get" do #Retrieve a payment method by its id
    
    context "existing payment method" do
      subject { Payments::PaymentMethod.get(:test_payment_method) }
      it { should be_a_kind_of Payments::PaymentMethod }
    end

    context "non existing payment method" do
      subject { Payments::PaymentMethod.get(:non_existing)}
      it { should be_nil }
    end

  end

  describe ".available" do # Retrieve the available payment methods
    
    context "not configured payments.available_methods" do
      before { SystemConfiguration::Variable.stub(:get_value) {''} }
      subject { Payments::PaymentMethod.available }
      it { should be_an_instance_of Array }
      it { should be_empty}
    end

    context "configured payments.available_methods" do
      before { SystemConfiguration::Variable.stub(:get_value) { 'test_payment_method' } }
      subject { Payments::PaymentMethod.available }
      it { should include(@test_payment_method) }
    end

  end
	
  describe ".available=" do

    context "Existing payment methods assignment" do

      it "should assign single string/array item" do
        SystemConfiguration::Variable.should_receive(:set_value).
          with('payments.available_methods', 'test_payment_method').twice

        Payments::PaymentMethod.available= 'test_payment_method'
        Payments::PaymentMethod.available= [:test_payment_method]
      end
      
      it "should assign multiple from string/array" do
        SystemConfiguration::Variable.should_receive(:set_value).
          with('payments.available_methods', 
          'test_payment_method, test_payment_method_2').twice 

        Payments::PaymentMethod.available= 'test_payment_method, test_payment_method_2'
        Payments::PaymentMethod.available= [:test_payment_method, 
          :test_payment_method_2]
      end

    end
    
    context "Non existing payment methods assignment" do
   
      it "should not assign from string" do
        SystemConfiguration::Variable.should_not_receive(:set_value)
        Payments::PaymentMethod.available= 'non_existing'
      end
      
      it "should not assign from array" do
        SystemConfiguration::Variable.should_not_receive(:set_value)
        Payments::PaymentMethod.available= [:non_existing]
      end
   
      it "should assign a payment method of two" do

        SystemConfiguration::Variable.should_receive(:set_value).
          with('payments.available_methods', 'test_payment_method').twice

        Payments::PaymentMethod.available= 'test_payment_method, non_existing'
        Payments::PaymentMethod.available= [:test_payment_method, :non_existing]

      end

    end

  end

end