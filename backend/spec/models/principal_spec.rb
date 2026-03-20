# frozen_string_literal: true

require "rails_helper"

RSpec.describe Principal do
  describe "#initialize" do
    it "extracts sub, email, and roles from claims" do
      claims = {
        "sub" => "user-123",
        "email" => "frodo@shire.example.com",
        "roles" => %w[fellowship ring-bearer]
      }

      principal = described_class.new(claims)

      expect(principal.sub).to eq("user-123")
      expect(principal.email).to eq("frodo@shire.example.com")
      expect(principal.roles).to eq(%w[fellowship ring-bearer])
    end

    it "extracts roles from realm_access.roles (Keycloak format)" do
      claims = {
        "sub" => "user-456",
        "realm_access" => { "roles" => %w[admin editor] }
      }

      principal = described_class.new(claims)

      expect(principal.roles).to eq(%w[admin editor])
    end

    it "extracts roles from groups claim (Dex format)" do
      claims = {
        "sub" => "user-789",
        "groups" => %w[developers ops]
      }

      principal = described_class.new(claims)

      expect(principal.roles).to eq(%w[developers ops])
    end

    it "defaults roles to empty array when no role claim is present" do
      claims = { "sub" => "user-000" }

      principal = described_class.new(claims)

      expect(principal.roles).to eq([])
    end

    it "freezes the claims hash" do
      claims = { "sub" => "user-123" }
      principal = described_class.new(claims)

      expect(principal.claims).to be_frozen
    end
  end

  describe "#to_h" do
    it "returns a hash with sub, email, and roles" do
      claims = {
        "sub" => "user-123",
        "email" => "frodo@shire.example.com",
        "roles" => %w[fellowship]
      }

      principal = described_class.new(claims)

      expect(principal.to_h).to eq({
        sub: "user-123",
        email: "frodo@shire.example.com",
        roles: %w[fellowship]
      })
    end
  end
end
