# frozen_string_literal: true

# Automatically inject a valid JWT Authorization header into all request specs.
# This ensures existing specs continue to pass after JWT auth is enabled globally.
#
# To test unauthenticated behavior, use the :skip_auth metadata:
#   it "returns 401", :skip_auth do ...
#
# Or manually override headers in your test.
RSpec.configure do |config|
  config.before(:each, type: :request) do |example|
    next if example.metadata[:skip_auth]

    @jwt_auth_headers = {
      "Authorization" => "Bearer #{JwtTestHelper.generate_token}"
    }
  end
end

# Monkey-patch request helpers to auto-inject auth headers.
# This is the least-invasive way to ensure all existing specs pass.
module AuthenticatedRequestHelper
  %i[get post put patch delete head].each do |method|
    define_method(method) do |path, **kwargs|
      if defined?(@jwt_auth_headers) && @jwt_auth_headers
        kwargs[:headers] = (@jwt_auth_headers).merge(kwargs[:headers] || {})
      end
      super(path, **kwargs)
    end
  end
end

RSpec.configure do |config|
  config.include AuthenticatedRequestHelper, type: :request
end
