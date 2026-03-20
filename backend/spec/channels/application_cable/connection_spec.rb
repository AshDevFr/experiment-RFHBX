# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationCable::Connection, type: :channel do
  describe "connect" do
    context "with a valid JWT in the query param" do
      it "successfully connects and sets current_principal" do
        token = JwtTestHelper.generate_token
        connect "/cable?token=#{token}"

        expect(connection.current_principal).to be_present
        expect(connection.current_principal).to be_a(Principal)
        expect(connection.current_principal.sub).to eq("user-123")
      end
    end

    context "with a valid JWT in the Authorization header" do
      it "successfully connects and sets current_principal" do
        token = JwtTestHelper.generate_token
        connect "/cable", headers: { "Authorization" => "Bearer #{token}" }

        expect(connection.current_principal).to be_present
        expect(connection.current_principal).to be_a(Principal)
        expect(connection.current_principal.sub).to eq("user-123")
      end
    end

    context "with no token" do
      it "rejects the connection" do
        expect { connect "/cable" }.to have_rejected_connection
      end
    end

    context "with an expired token" do
      it "rejects the connection" do
        token = JwtTestHelper.generate_expired_token
        expect { connect "/cable?token=#{token}" }.to have_rejected_connection
      end
    end

    context "with a tampered/invalid token" do
      it "rejects the connection" do
        token = JwtTestHelper.generate_tampered_token
        expect { connect "/cable?token=#{token}" }.to have_rejected_connection
      end
    end

    context "with a malformed token string" do
      it "rejects the connection" do
        expect { connect "/cable?token=not-a-valid-jwt" }.to have_rejected_connection
      end
    end
  end

  describe "disconnect" do
    it "closes an authenticated connection cleanly" do
      token = JwtTestHelper.generate_token
      connect "/cable?token=#{token}"
      expect { disconnect }.not_to raise_error
    end
  end
end
