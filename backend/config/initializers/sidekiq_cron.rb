# frozen_string_literal: true

Sidekiq::Cron.configure do |config|
  config.cron_poll_interval = 5 # Must be lower than the tick cron interval
end
