require 'spec_helper'

describe 'Stub app PaymentIntent state branching' do
  describe 'create' do
    it 'returns the existing succeeded fixture by default' do
      pi = Stripe::PaymentIntent.create(amount: 2000, currency: 'usd')

      expect(pi.status).to eq('requires_payment_method')
    end

    it 'returns requires_action when metadata[fake_stripe_scenario]=requires_action' do
      pi = Stripe::PaymentIntent.create(
        amount: 2000,
        currency: 'usd',
        metadata: { fake_stripe_scenario: 'requires_action' }
      )

      expect(pi.status).to eq('requires_action')
      expect(pi.next_action.type).to eq('use_stripe_sdk')
    end

    it 'returns declined when metadata[fake_stripe_scenario]=declined' do
      pi = Stripe::PaymentIntent.create(
        amount: 2000,
        currency: 'usd',
        metadata: { fake_stripe_scenario: 'declined' }
      )

      expect(pi.status).to eq('requires_payment_method')
      expect(pi.last_payment_error.code).to eq('card_declined')
      expect(pi.last_payment_error.decline_code).to eq('generic_decline')
    end
  end

  describe 'retrieve' do
    it 'returns requires_action for pi_requires_action_* ids' do
      pi = Stripe::PaymentIntent.retrieve('pi_requires_action_test123')

      expect(pi.status).to eq('requires_action')
    end

    it 'returns declined for pi_declined_* ids' do
      pi = Stripe::PaymentIntent.retrieve('pi_declined_test123')

      expect(pi.status).to eq('requires_payment_method')
      expect(pi.last_payment_error.code).to eq('card_declined')
    end

    it 'returns the default fixture for other ids' do
      pi = Stripe::PaymentIntent.retrieve('pi_1GLrZO2eZvKYlo2CfMpq8zT8')

      expect(pi.status).to eq('succeeded')
    end
  end

  describe 'confirm' do
    it 'honors the same id sentinel for non-happy-path states' do
      pi = Stripe::PaymentIntent.confirm('pi_requires_action_test123')

      expect(pi.status).to eq('requires_action')
    end
  end
end
