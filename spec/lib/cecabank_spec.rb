require 'spec_helper'

describe "Cecabank gateway payment" do 

  describe "uno" do

    let(:charge) { Payments::Charge.create({:amount => 150})}
    let(:cecabank) { Payments::PaymentMethod.get(:cecabank)}

    it "should" do
      
      puts "cecabank: #{cecabank.description}"
      puts "cecabank chargeform: #{cecabank.charge_form(charge)}"
    
    end
	
  end

end