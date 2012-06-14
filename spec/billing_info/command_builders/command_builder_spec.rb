require 'spec_helper'
describe BillingLogic::CommandBuilders::ActionObject do
  it "should return the correct product" do
    command = "remove (B @ $20/mo & C @ $20/mo) from [(A @ $30/mo & B @ $20/mo & C @ $20/mo) @ $70/mo] now"
    BillingLogic::CommandBuilders::ActionObject.from_string(command).to_s.should == command
  end
end

