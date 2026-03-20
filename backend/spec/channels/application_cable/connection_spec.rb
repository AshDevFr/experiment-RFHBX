# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationCable::Connection, type: :channel do
  describe "connect" do
    it "successfully connects and assigns a connection_identifier" do
      connect "/cable"

      expect(connection.connection_identifier).to be_present
      expect(connection.connection_identifier).to match(/\A[0-9a-f-]{36}\z/)
    end

    it "assigns a unique identifier per connection" do
      connect "/cable"
      first_id = connection.connection_identifier

      # Disconnect and reconnect to get a new identifier
      disconnect

      connect "/cable"
      second_id = connection.connection_identifier

      expect(first_id).not_to eq(second_id)
    end
  end

  describe "disconnect" do
    it "closes the connection cleanly" do
      connect "/cable"
      expect { disconnect }.not_to raise_error
    end
  end
end
