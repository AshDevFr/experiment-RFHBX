# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    description "The query root of this schema"

    # Placeholder field – real queries added in Phase 3.2+
    field :health, String, null: false, description: "Returns ok when the GraphQL endpoint is alive"

    def health
      "ok"
    end
  end
end
