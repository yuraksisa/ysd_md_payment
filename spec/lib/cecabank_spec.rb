require 'spec_helper'

describe "Cecabank gateway payment" do 

  describe "uno" do

    let(:cecabank) { Payments::PaymentMethod.get(:cecabank)}

    it "should" do
      
      puts "cecabank: #{cecabank.description}"
      puts "cecabank chargeform: #{cecabank.charge_form({:amount => 150.00, :reference => '1234567890'})}"
    
    end
	
  end

end