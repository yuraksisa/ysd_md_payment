require 'spec_helper'

describe "Cecabank gateway payment" do 

  describe "dos" do

    let(:bank_transfer) { Payments::PaymentMethod.get(:bank_transfer)}

    it "should" do
    
      puts bank_transfer.description
    
    end
	
  end

end