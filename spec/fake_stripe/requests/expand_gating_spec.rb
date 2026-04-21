require 'spec_helper'

describe 'Stub app expand gating (basil parity)' do
  describe 'Customer.retrieve' do
    it 'omits sources by default (basil shape)' do
      customer = Stripe::Customer.retrieve('cus_test123')

      expect(customer.respond_to?(:sources) ? customer.sources : nil).to be_nil
    end

    it 'includes sources.data when expand[]=sources' do
      customer = Stripe::Customer.retrieve(id: 'cus_test123', expand: ['sources'])

      expect(customer.sources.data).to be_an(Array)
      expect(customer.sources.data.first.object).to eq('bank_account')
    end
  end

  describe 'Charge.retrieve' do
    it 'omits refunds by default (basil shape)' do
      charge = Stripe::Charge.retrieve('ch_test123')

      expect(charge.respond_to?(:refunds) ? charge.refunds : nil).to be_nil
    end

    it 'includes refunds when expand[]=refunds' do
      charge = Stripe::Charge.retrieve(id: 'ch_test123', expand: ['refunds'])

      expect(charge.refunds).to be_a(Stripe::StripeObject)
    end
  end
end
