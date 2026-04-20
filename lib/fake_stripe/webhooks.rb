require 'json'
require 'net/http'
require 'openssl'
require 'uri'
require 'securerandom'

module FakeStripe
  # Helpers for simulating Stripe webhook events in tests. Real Stripe signs
  # each webhook POST with an HMAC-SHA256 signature over "timestamp.payload"
  # using a whsec_* secret, and the app verifies it via
  # Stripe::Webhook.construct_event. This module produces signature-compatible
  # payloads so those verification paths exercise the real code.
  #
  # Example in a request spec:
  #
  #   webhook = FakeStripe::Webhooks.build(event_type: 'payout.paid')
  #   post webhooks_stripe_path, params: webhook.payload, headers: webhook.headers
  module Webhooks
    # Maps an event type to the object fixture that best represents its
    # data.object. Events not listed here fall back to Webhooks.build accepting
    # an explicit object: argument.
    EVENT_TYPE_FIXTURES = {
      # Charge
      'charge.succeeded'                 => 'retrieve_charge',
      'charge.failed'                    => 'retrieve_charge',
      'charge.pending'                   => 'retrieve_charge',
      'charge.captured'                  => 'capture_charge',
      'charge.updated'                   => 'retrieve_charge',
      'charge.refunded'                  => 'retrieve_charge',
      'charge.refund.updated'            => 'retrieve_refund',
      # Charge disputes
      'charge.dispute.created'           => 'retrieve_dispute',
      'charge.dispute.updated'           => 'update_dispute',
      'charge.dispute.closed'            => 'close_dispute',
      'charge.dispute.funds_withdrawn'   => 'retrieve_dispute',
      'charge.dispute.funds_reinstated'  => 'retrieve_dispute',
      # PaymentIntent
      'payment_intent.created'                      => 'create_payment_intent',
      'payment_intent.succeeded'                    => 'retrieve_payment_intent',
      'payment_intent.payment_failed'               => 'retrieve_payment_intent',
      'payment_intent.amount_capturable_updated'    => 'retrieve_payment_intent',
      # PaymentMethod
      'payment_method.attached'                => 'retrieve_payment_method',
      'payment_method.detached'                => 'retrieve_payment_method',
      'payment_method.automatically_updated'   => 'retrieve_payment_method',
      # Transfer
      'transfer.created'  => 'create_transfer',
      'transfer.updated'  => 'update_transfer',
      'transfer.reversed' => 'create_transfer_reversal',
      'transfer.paid'     => 'retrieve_transfer',
      # Payout
      'payout.paid'      => 'retrieve_payout_paid',
      'payout.created'   => 'create_payout',
      'payout.updated'   => 'update_payout',
      'payout.failed'    => 'retrieve_payout_failed',
      'payout.canceled'  => 'retrieve_payout_canceled',
      # Customer
      'customer.created'          => 'create_customer',
      'customer.source.updated'   => 'update_card',
      'customer.source.deleted'   => 'delete_card',
      # Account
      'account.updated' => 'retrieve_account'
    }.freeze

    Result = Struct.new(:payload, :signature, :event, keyword_init: true) do
      # Headers to pass alongside the payload when POSTing to the webhook
      # endpoint. Matches what real Stripe sends.
      def headers
        {
          'Content-Type'     => 'application/json',
          'Stripe-Signature' => signature
        }
      end
    end

    # Builds a signed event. Returns a Result with `payload` (JSON string),
    # `signature` (Stripe-Signature header value), `headers`, and `event`
    # (the event hash).
    #
    # @param event_type [String] e.g. "payout.paid"
    # @param object [Hash, nil] data.object hash. Defaults to the fixture
    #   mapped from event_type. Pass to override or when no mapping exists.
    # @param overrides [Hash] deep-merged into data.object before signing
    # @param secret [String] signing secret (defaults to
    #   FakeStripe.webhook_secret)
    # @param timestamp [Integer] UNIX seconds, defaults to Time.now
    def self.build(event_type:, object: nil, overrides: {}, secret: nil, timestamp: nil)
      secret    ||= FakeStripe.webhook_secret
      timestamp ||= Time.now.to_i
      object    ||= load_fixture_for(event_type)
      object      = deep_merge(object, overrides) unless overrides.empty?

      event = event_envelope(event_type: event_type, object: object, timestamp: timestamp)
      payload = JSON.generate(event)
      signature = sign(payload: payload, secret: secret, timestamp: timestamp)

      Result.new(payload: payload, signature: signature, event: event)
    end

    # Convenience: build + HTTP POST to the given URL. Returns Net::HTTPResponse.
    # Prefer `build` in request specs where the framework (Rack::Test) dispatches.
    def self.trigger(event_type:, url:, object: nil, overrides: {}, secret: nil, timestamp: nil)
      result = build(
        event_type: event_type,
        object:     object,
        overrides:  overrides,
        secret:     secret,
        timestamp:  timestamp
      )

      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      request = Net::HTTP::Post.new(uri.request_uri, result.headers)
      request.body = result.payload
      http.request(request)
    end

    # Build a Stripe-Signature header value: "t=<ts>,v1=<hex>"
    def self.sign(payload:, secret:, timestamp:)
      signed_payload = "#{timestamp}.#{payload}"
      hex = OpenSSL::HMAC.hexdigest('SHA256', secret, signed_payload)
      "t=#{timestamp},v1=#{hex}"
    end

    def self.load_fixture_for(event_type)
      fixture_name = EVENT_TYPE_FIXTURES[event_type]
      raise ArgumentError, "No object fixture mapped for event '#{event_type}'. Pass `object:` explicitly." unless fixture_name

      path = File.join(FakeStripe.fixture_path, "#{fixture_name}.json")
      raise ArgumentError, "Fixture not found: #{path}" unless File.exist?(path)

      JSON.parse(File.read(path))
    end

    def self.event_envelope(event_type:, object:, timestamp:)
      {
        'id'               => "evt_#{SecureRandom.hex(12)}",
        'object'           => 'event',
        'api_version'      => '2025-03-31.basil',
        'created'          => timestamp,
        'data'             => { 'object' => object },
        'livemode'         => false,
        'pending_webhooks' => 1,
        'request'          => {
          'id'              => "req_#{SecureRandom.hex(8)}",
          'idempotency_key' => nil
        },
        'type'             => event_type
      }
    end

    def self.deep_merge(base, overrides)
      base.merge(overrides) do |_key, base_val, override_val|
        if base_val.is_a?(Hash) && override_val.is_a?(Hash)
          deep_merge(base_val, override_val)
        else
          override_val
        end
      end
    end
  end
end
