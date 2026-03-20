# frozen_string_literal: true

require "webmock/rspec"

# Allow localhost connections for request specs, block everything else
WebMock.disable_net_connect!(allow_localhost: true)
