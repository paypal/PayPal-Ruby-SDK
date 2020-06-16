require 'spec_helper'

describe ::PayPal::SDK::REST::DataTypes::WebhookEvent do
  describe '.get_resource_class' do
    context 'when the resource name matches a defined constant' do
      it 'returns a symbol for const_get' do
        expect(described_class.get_resource_class('Payment')).to eq(:Payment)
      end
    end

    context 'when the resource name is unknown' do
      it 'returns nil' do
        expect(described_class.get_resource_class('some-unknown-resource-type')).to eq(nil)
      end
    end

  end
end
