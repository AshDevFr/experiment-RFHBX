# frozen_string_literal: true

class RemoveTickIntervalSecondsFromSimulationConfigs < ActiveRecord::Migration[8.1]
  def change
    remove_column :simulation_configs, :tick_interval_seconds, :integer
  end
end
