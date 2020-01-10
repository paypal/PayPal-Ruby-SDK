require "spec_helper"

describe "Payouts", :integration => true do


  PayoutVenmotAttributes = {
    :sender_batch_header => {
      :sender_batch_id => SecureRandom.hex(8)
  },
  :items => [
      {
          :recipient_type => 'Phone',
          :amount => {
              :value => '1.0',
              :currency => 'USD'
          },
          :note => 'Thanks for your patronage!',
          :sender_item_id => '2014031400023',
          :receiver => '1238675309',
          :recipient_wallet => 'Venmo'
      }
    ]
  }

  PayoutAttributes = {
      :sender_batch_header => {
          :sender_batch_id => SecureRandom.hex(8),
          :email_subject => 'You have a Payout!'
      },
      :items => [
          {
              :recipient_type => 'EMAIL',
              :amount => {
                  :value => '1.0',
                  :currency => 'USD'
              },
              :note => 'Thanks for your patronage!',
              :sender_item_id => '2014031400023',
              :receiver => 'shirt-supplier-one@mail.com'
          }
      ]
  }

  it "create payout sync" do
    $payout = PayPal::SDK::REST::Payout.new(PayoutAttributes)
    $payout_batch = $payout.create(true)
    expect($payout_batch).to be_truthy
  end

  it "create venmo payout" do 
    $payout = PayPal::SDK::REST::Payout.new(PayoutVenmotAttributes)
    $payout_batch = $payout.create(true)
    expect($payout_batch).to be_truthy
  end

  it "get payout batch status" do
    $result = PayPal::SDK::REST::Payout.get($payout_batch.batch_header.payout_batch_id)
    expect($result).to be_a PayPal::SDK::REST::PayoutBatch
    expect($payout_batch.batch_header.payout_batch_id).to eql $result.batch_header.payout_batch_id
  end

  it "get payout item status" do
    $payout_item_details= PayoutItem.get($payout_batch.items[0].payout_item_id)
    expect($payout_item_details).to be_a PayPal::SDK::REST::PayoutItemDetails
    expect($payout_item_details.payout_item_id).to eql $payout_batch.items[0].payout_item_id
  end

  it "cancel unclaimed payouts" do
    $payout_item_details= PayoutItem.cancel($payout_batch.items[0].payout_item_id)
    expect($payout_item_details).to be_a PayPal::SDK::REST::PayoutItemDetails
    expect($payout_item_details.payout_item_id).to eql $payout_batch.items[0].payout_item_id
    expect($payout_item_details.transaction_status).to eql 'RETURNED'
  end

end
