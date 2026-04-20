require 'spec_helper'

describe FakeStripe::Webhooks do
  describe '.build' do
    it 'returns a signed payload that Stripe::Webhook.construct_event accepts' do
      result = described_class.build(event_type: 'charge.succeeded')
      event = Stripe::Webhook.construct_event(
        result.payload,
        result.signature,
        FakeStripe.webhook_secret
      )

      expect(event.type).to eq('charge.succeeded')
      expect(event.data.object.object).to eq('charge')
    end

    it 'raises when an event type has no fixture mapping and no object override' do
      expect {
        described_class.build(event_type: 'invoice.unknown_thing')
      }.to raise_error(ArgumentError, /No object fixture mapped/)
    end

    it 'accepts an explicit object when no fixture mapping exists' do
      result = described_class.build(
        event_type: 'invoice.custom',
        object: { 'id' => 'in_test', 'object' => 'invoice' }
      )
      event = Stripe::Webhook.construct_event(
        result.payload,
        result.signature,
        FakeStripe.webhook_secret
      )

      expect(event.type).to eq('invoice.custom')
      expect(event.data.object.id).to eq('in_test')
    end

    it 'deep-merges overrides into the object' do
      result = described_class.build(
        event_type: 'charge.succeeded',
        overrides: { 'amount' => 9999, 'metadata' => { 'order_id' => 'custom' } }
      )
      event = Stripe::Webhook.construct_event(
        result.payload,
        result.signature,
        FakeStripe.webhook_secret
      )

      expect(event.data.object.amount).to eq(9999)
      expect(event.data.object.metadata.order_id).to eq('custom')
    end

    it 'rejects an altered payload (signature changes)' do
      result = described_class.build(event_type: 'charge.succeeded')
      tampered = result.payload.sub('"object":"charge"', '"object":"invoice"')

      expect {
        Stripe::Webhook.construct_event(tampered, result.signature, FakeStripe.webhook_secret)
      }.to raise_error(Stripe::SignatureVerificationError)
    end

    it 'exposes Stripe-Signature and Content-Type in headers' do
      result = described_class.build(event_type: 'charge.succeeded')

      expect(result.headers['Stripe-Signature']).to match(/\At=\d+,v1=[0-9a-f]{64}\z/)
      expect(result.headers['Content-Type']).to eq('application/json')
    end
  end

  describe '.sign' do
    it 'produces a signature Stripe::Webhook::Signature.verify_header accepts' do
      payload = '{"type":"test"}'
      timestamp = Time.now.to_i
      secret = 'whsec_test_signing'

      signature = described_class.sign(
        payload: payload,
        secret: secret,
        timestamp: timestamp
      )

      expect {
        Stripe::Webhook::Signature.verify_header(payload, signature, secret)
      }.not_to raise_error
    end
  end
end
