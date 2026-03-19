# frozen_string_literal: true

class AddTickCountToSimulationConfigs < ActiveRecord::Migration[8.1]
  def change
    add_column :simulation_configs, :tick_count, :integer, null: false, default: 0
  end
end
