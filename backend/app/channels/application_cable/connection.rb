# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :connection_identifier

    def connect
      # Stub identity — authentication via OIDC is planned for Phase 6.
      # For now, assign a random UUID so each connection has a unique identifier
      # that channels can use without requiring a logged-in user.
      self.connection_identifier = SecureRandom.uuid
    end
  end
end
