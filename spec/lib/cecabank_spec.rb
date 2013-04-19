require 'spec_helper'

describe "Cecabank gateway payment" do 

  describe "uno" do

    let(:charge) { Payments::Charge.create({:amount => 150})}
    let(:cecabank) { Payments::PaymentMethod.get(:cecabank)}
	
  end

end