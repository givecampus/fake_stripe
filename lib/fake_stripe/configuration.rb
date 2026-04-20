module FakeStripe
  module Configuration
    attr_writer :fixture_path, :webhook_secret

    DEFAULT_FIXTURE_PATH = File.join(File.dirname(__FILE__), 'fixtures/')
    DEFAULT_WEBHOOK_SECRET = 'whsec_test_fake_stripe_secret'.freeze

    def fixture_path
      @fixture_path or DEFAULT_FIXTURE_PATH
    end

    def webhook_secret
      @webhook_secret or DEFAULT_WEBHOOK_SECRET
    end

    def configure
      yield self
    end
  end
end
