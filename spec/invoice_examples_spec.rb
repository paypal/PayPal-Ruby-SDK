require "spec_helper"

describe "Invoice" do

  InvoiceAttributes = {
    "merchant_info" => {
      "email" => "PPX.DevNet-facilitator@gmail.com"
    },
    "billing_info" => [ { "email" => "example@example.com" } ],
    "items" => [
      {
        "name" => "Sutures",
        "quantity" => 100,
        "unit_price" => {
          "currency" => "USD",
          "value" => 5
        }
      }
    ],
    "note" => "Medical Invoice 16 Jul, 2013 PST"
  }

  it "create invoice" do
    invoice = PayPal::SDK::REST::Invoice.new(InvoiceAttributes)
    invoice.create.should be_true
  end

  it "list invoice" do
    history = PayPal::SDK::REST::Invoice.get_all( :total_count_required =>true )
    history.total_count.should_not be_nil
  end

  it "get invoice" do
    invoice = PayPal::SDK::REST::Invoice.find("INV2-P6VJ-36HG-BBVT-M2MA")
    invoice.should be_a PayPal::SDK::REST::Invoice
    invoice.id.should eql "INV2-P6VJ-36HG-BBVT-M2MA"
  end
end
