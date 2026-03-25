# frozen_string_literal: true

# Defensive migration: ensure the `level` column on `characters` has a
# DB-level default of 1 and backfill any existing rows where level is nil
# or less than 1.  This prevents `QuestTickWorker` from raising
# `ActiveRecord::RecordInvalid: Validation failed: Level must be greater than 0`
# when processing characters that were created before this default was enforced.
class FixCharacterLevelDefault < ActiveRecord::Migration[8.1]
  def up
    # Ensure the DB-level default is 1 (idempotent: safe to run even if already 1)
    change_column_default :characters, :level, from: 0, to: 1

    # Backfill any existing rows that have a nil or zero level
    Character.where("level IS NULL OR level < 1").update_all(level: 1)
  end

  def down
    change_column_default :characters, :level, from: 1, to: 0
  end
end
