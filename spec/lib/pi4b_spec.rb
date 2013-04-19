require 'spec_helper'
require 'ysd_md_configuration' unless defined?SystemConfiguration::SecureVariable

describe "PI4B gateway payment" do 

  let(:charge) { Payments::Charge.create({:amount => 150, 
  	:payment_method_id => :pi4b,
  	:currency => 'EUR'})}
  
  let(:pi4b)   { Payments::PaymentMethod.get(:pi4b)}

  let(:charge_detail_data) do
     [{:item_reference => 'DEPOSIT',
       :item_description => 'CLASE A',
       :item_units => 1,
       :item_price => 150}]
  end
  
  let(:charge_form) do
      result = <<-EOF
        <form action="http://prueba.com" method="POST" name="gateway">
          <input type="hidden" name="order" value="#{charge.id}">
          <input type="hidden" name="store" value="123456">
        </form>
        <script type="text/javascript">
          window.onload = function() {
            document.forms['gateway'].submit();
          }
        </script>
      EOF
  end
  
  let(:charge_detail) do
      result = []
      result << "M97815000"
      result << "1"
      result << "DEPOSIT"
      result << "CLASE A"
      result << "1"
      result << "15000"
      result.join('\n')
  end
  
  describe ".charge_form" do
	
    before :each do
      SystemConfiguration::SecureVariable.should_receive(:get_value).with('payments.pi4b.merchant_id').
        and_return('123456')
      SystemConfiguration::SecureVariable.should_receive(:get_value).with('payments.pi4b.url').
        and_return('http://prueba.com')
    end

    subject { pi4b.charge_form(charge) }
    it { should == charge_form }

  end

  describe ".charge_detail" do
    
    context "charge exists" do
      before :each do
        Payments::Charge.should_receive(:get).with(charge.id).and_return(charge)
        charge.should_receive(:detail).any_number_of_times.and_return(charge_detail_data)
      end

      subject { pi4b.charge_detail(:store => '1234', :order => charge.id) }
      it { should == charge_detail }
    end

    context "charge does not exist" do

    end

  end

end