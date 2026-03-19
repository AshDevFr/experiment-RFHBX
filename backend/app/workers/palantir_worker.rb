# frozen_string_literal: true

class PalantirWorker
  include Shoryuken::Worker

  shoryuken_options queue: ENV.fetch("SQS_QUEUE_NAME", "palantir-queue"), auto_delete: true

  # Processes a Palantir message from SQS.
  # Creates a QuestEvent with event_type :progress on the most recent active quest.
  def perform(_sqs_msg, body)
    parsed = begin
      JSON.parse(body)
    rescue JSON::ParserError, TypeError
      { "message" => body.to_s }
    end

    message = parsed.is_a?(Hash) ? parsed["message"].to_s : body.to_s

    quest = Quest.where(status: :active).order(created_at: :desc).first
    return unless quest

    QuestEvent.create!(
      quest:      quest,
      event_type: :progress,
      data:       { "message" => message }
    )
  end
end
