require 'spec_helper'

describe 'Stub app PaymentMethod us_bank_account branching' do
  describe 'POST /v1/payment_methods' do
    it 'returns a us_bank_account payment method when type is us_bank_account' do
      payment_method = Stripe::PaymentMethod.create({
        type: 'us_bank_account',
        us_bank_account: {
          account_holder_type: 'individual',
          account_number: '000123456789',
          routing_number: '110000000',
        },
      })

      expect(payment_method.type).to eq('us_bank_account')
      expect(payment_method.us_bank_account.bank_name).to eq('STRIPE TEST BANK')
      expect(payment_method.us_bank_account.last4).to eq('6789')
      expect(payment_method.us_bank_account.routing_number).to eq('110000000')
    end

    it 'still returns a card payment method by default' do
      payment_method = Stripe::PaymentMethod.create

      expect(payment_method.type).to eq('card')
    end
  end

  describe 'GET /v1/payment_methods' do
    it 'returns us_bank_account payment methods when type is us_bank_account' do
      result = Stripe::PaymentMethod.list({
        customer: 'cus_HJYfEnsfVLxB3C',
        type: 'us_bank_account',
      })

      expect(result.count).to eq(1)
      expect(result.data.first.type).to eq('us_bank_account')
      expect(result.data.first.us_bank_account.bank_name).to eq('STRIPE TEST BANK')
      expect(result.data.first.us_bank_account.last4).to eq('6789')
    end

    it 'still returns card payment methods for type card' do
      result = Stripe::PaymentMethod.list({
        customer: 'cus_HJYfEnsfVLxB3C',
        type: 'card',
      })

      expect(result.data.first.type).to eq('card')
    end
  end

  describe 'GET /v1/payment_methods/:id' do
    it 'returns a us_bank_account payment method for ids prefixed with pm_usba_' do
      payment_method = Stripe::PaymentMethod.retrieve('pm_usba_test123')

      expect(payment_method.type).to eq('us_bank_account')
      expect(payment_method.us_bank_account.bank_name).to eq('STRIPE TEST BANK')
      expect(payment_method.us_bank_account.account_type).to eq('checking')
    end

    it 'returns a card payment method for any other id' do
      payment_method = Stripe::PaymentMethod.retrieve('pm_1FzVb62eZvKYlo2CKPwNF9Bz')

      expect(payment_method.type).to eq('card')
    end
  end

  describe 'POST /v1/payment_methods/:id/attach' do
    it 'returns a us_bank_account payment method for ids prefixed with pm_usba_' do
      result = Stripe::PaymentMethod.attach('pm_usba_test123', {customer: 'cus_HJYfEnsfVLxB3C'})

      expect(result.type).to eq('us_bank_account')
      expect(result.customer).to eq('cus_HJYfEnsfVLxB3C')
    end
  end

  describe 'POST /v1/payment_methods/:id/detach' do
    it 'returns a us_bank_account payment method for ids prefixed with pm_usba_' do
      result = Stripe::PaymentMethod.detach('pm_usba_test123')

      expect(result.type).to eq('us_bank_account')
      expect(result.customer).to be_nil
    end
  end
end
