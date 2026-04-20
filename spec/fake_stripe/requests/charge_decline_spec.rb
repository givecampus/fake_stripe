require 'spec_helper'

describe 'Stub app Charge decline simulation' do
  it 'returns the existing succeeded fixture by default' do
    charge = Stripe::Charge.create(amount: 2000, currency: 'usd')

    expect(charge.status).to eq('succeeded')
  end

  it 'raises Stripe::CardError when metadata[fake_stripe_scenario]=declined' do
    expect {
      Stripe::Charge.create(
        amount: 2000,
        currency: 'usd',
        metadata: { fake_stripe_scenario: 'declined' }
      )
    }.to raise_error(Stripe::CardError) do |error|
      expect(error.http_status).to eq(402)
      expect(error.code).to eq('card_declined')
      expect(error.json_body.dig(:error, :decline_code)).to eq('generic_decline')
      expect(error.message).to include('Your card was declined')
    end
  end
end
