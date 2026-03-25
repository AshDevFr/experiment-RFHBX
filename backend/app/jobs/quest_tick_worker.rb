# frozen_string_literal: true

class QuestTickWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default, retry: 3

  # How many seconds between ticks.
  # Override via QUEST_TICK_INTERVAL env var.
  # Default: 5 s in development/test for fast feedback; 60 s in production.
  TICK_INTERVAL = ENV.fetch("QUEST_TICK_INTERVAL", Rails.env.production? ? 60 : 5).to_i

  def perform
    config = SimulationConfig.current
    return unless config.running?

    config.increment!(:tick_count)

    process_active_quests(config)

    if config.campaign?
      advance_campaign(config)
    else
      ensure_random_quest(config)
    end

    # Schedule the next tick at the configured interval so sub-minute
    # frequencies are possible. The sidekiq-cron entry acts as a
    # bootstrap / dead-chain reviver and fires at most once per minute.
    self.class.perform_in(TICK_INTERVAL)
  end

  private

  def process_active_quests(config)
    Quest.where(status: :active).find_each do |quest|
      if quest.quest_memberships.none?
        Rails.logger.warn("[QuestTickWorker] Skipping memberless quest ##{quest.id}: #{quest.title.inspect}")
        next
      end

      # Collect level_up events created inside the transaction so we can
      # broadcast them AFTER the transaction commits, avoiding premature
      # broadcasts that could race ahead of the DB write.
      @pending_level_up_events = []

      ActiveRecord::Base.transaction do
        tick_quest(quest, config)
      end

      @pending_level_up_events.each { |e| QuestEventBroadcaster.broadcast(e) }
      @pending_level_up_events = []
    end
  end

  def tick_quest(quest, config)
    increment = rand_progress(config.progress_min, config.progress_max)
    quest.progress += increment
    quest.save!

    event = QuestEvent.create!(
      quest: quest,
      event_type: :progress,
      message: generate_progress_message(quest),
      data: { progress: quest.progress.to_f, increment: increment.to_f }
    )

    QuestEventBroadcaster.broadcast(event)

    resolve_quest(quest, config) if quest.progress >= 1.0
  end

  def resolve_quest(quest, config)
    party_power = calculate_party_power(quest)
    success_chance = calculate_success_chance(party_power, quest.danger_level)
    if rand(100.0) < success_chance
      handle_success(quest, config)
    else
      handle_failure(quest)
    end
  end

  def calculate_party_power(quest)
    quest.characters.includes(:artifacts).sum do |character|
      base_stats = character.strength + character.wisdom + character.endurance
      artifact_bonuses = character.artifacts.sum do |artifact|
        bonus = artifact.stat_bonus || {}
        (bonus["strength"] || 0) + (bonus["wisdom"] || 0) + (bonus["endurance"] || 0)
      end
      (base_stats + artifact_bonuses) * (1 + 0.1 * character.level)
    end
  end

  def calculate_success_chance(party_power, danger_level)
    raw = (party_power / (danger_level * 100.0)) * 50.0
    raw.clamp(5.0, 95.0)
  end

  def handle_success(quest, config)
    xp_reward = quest.danger_level * 100

    quest.characters.each do |character|
      character.xp += xp_reward
      check_level_up(character, quest)
      character.status = :idle
      character.save!
    end

    quest.update!(status: :completed, progress: 1.0)

    # Award artifact drops to party members before broadcasting completion
    ArtifactDropService.call(quest)

    QuestEvent.create!(
      quest: quest,
      event_type: :completed,
      message: "#{quest.title} completed successfully! Party earned #{xp_reward} XP each.",
      data: { xp_awarded: xp_reward, result: "success" }
    )

    broadcast_quest_update(quest, :completed)

    # Immediately enqueue auto-start so the next quest begins without waiting
    # for the next cron tick.  The worker is idempotent: if advance_campaign /
    # ensure_random_quest below already starts the next quest in this same tick,
    # QuestAutoStartWorker will detect the active quest and exit early.
    QuestAutoStartWorker.perform_async
  end

  def handle_failure(quest)
    xp_reward = quest.danger_level * 25

    quest.characters.each do |character|
      character.xp += xp_reward
      check_level_up(character, quest)
      character.save!
    end

    quest.update!(
      status: :failed,
      attempts: quest.attempts + 1
    )

    QuestEvent.create!(
      quest: quest,
      event_type: :failed,
      message: "#{quest.title} failed. The party earned #{xp_reward} XP and will try again.",
      data: { xp_awarded: xp_reward, result: "failure", attempts: quest.attempts }
    )

    # Reset and re-activate with same party
    quest.update!(status: :active, progress: 0.0)

    QuestEvent.create!(
      quest: quest,
      event_type: :restarted,
      message: "#{quest.title} has been restarted (attempt ##{quest.attempts + 1}).",
      data: { attempt: quest.attempts + 1 }
    )

    broadcast_quest_update(quest, :restarted)
  end

  def check_level_up(character, quest = nil)
    loop do
      next_level = character.level + 1
      xp_threshold = next_level * 500
      break unless character.xp >= xp_threshold

      character.level = next_level
      stat = %i[strength wisdom endurance].sample
      character.send(:"#{stat}=", character.send(stat) + 1)

      next unless quest

      event = QuestEvent.create!(
        quest: quest,
        event_type: :level_up,
        message: "#{character.name} reached level #{next_level}! #{stat.to_s.capitalize} increased by 1.",
        data: {
          character_id: character.id,
          character_name: character.name,
          new_level: next_level,
          stat_increased: stat.to_s
        }
      )
      @pending_level_up_events ||= []
      @pending_level_up_events << event
    end
  end

  def advance_campaign(config)
    # If there are active campaign quests, don't advance yet
    return if Quest.where(quest_type: :campaign, status: :active).exists?

    next_quest = Quest.where(quest_type: :campaign)
                      .where.not(status: :completed)
                      .order(:campaign_order)
                      .first

    if next_quest
      activate_campaign_quest(next_quest, config)
    else
      # Campaign complete — switch to random mode and immediately try to start a
      # random quest in the same tick rather than waiting for the next cron run.
      config.update!(mode: :random)
      ensure_random_quest(config)
    end
  end

  def activate_campaign_quest(quest, config)
    # Assign book-accurate party: use existing quest memberships if present,
    # otherwise assign idle characters
    if quest.quest_memberships.empty?
      idle_characters = Character.where(status: :idle).limit(4)
      idle_characters.each do |character|
        QuestMembership.find_or_create_by!(quest: quest, character: character) do |m|
          m.role = "Adventurer"
        end
      end
    end

    # Cannot activate without at least one member — skip and retry on the next tick.
    if quest.quest_memberships.none?
      Rails.logger.warn("[QuestTickWorker] Deferring campaign quest ##{quest.id} " \
                        "(#{quest.title.inspect}): no idle characters available to form a party")
      return
    end

    quest.characters.each do |character|
      character.update!(status: :on_quest)
    end

    quest.update!(status: :active, progress: 0.0)
    config.update!(campaign_position: quest.campaign_order || 0)

    QuestEvent.create!(
      quest: quest,
      event_type: :started,
      message: "#{quest.title} has begun!",
      data: { party: quest.characters.pluck(:name) }
    )

    broadcast_quest_update(quest, :started)
  end

  def ensure_random_quest(config) # rubocop:disable Lint/UnusedMethodArgument
    return if Quest.where(quest_type: :random, status: :active).exists?

    idle_characters = Character.where(status: :idle)
    return if idle_characters.count < 2

    quest = generate_random_quest
    party = idle_characters.order("RANDOM()").limit(rand(2..4))

    party.each do |character|
      QuestMembership.create!(quest: quest, character: character, role: "Adventurer")
      character.update!(status: :on_quest)
    end

    quest.update!(status: :active)

    QuestEvent.create!(
      quest: quest,
      event_type: :started,
      message: "#{quest.title} has begun with a party of #{party.count}!",
      data: { party: party.pluck(:name) }
    )

    broadcast_quest_update(quest, :started)
  end

  RANDOM_QUEST_TEMPLATES = [
    { title: "Patrol the Borders of %{region}", description: "Scout the perimeter of %{region} for signs of enemy activity." },
    { title: "Clear the Caves of %{region}", description: "Purge the dark creatures lurking in the caves near %{region}." },
    { title: "Escort the Merchant to %{region}", description: "Safely escort a merchant caravan through dangerous territory to %{region}." },
    { title: "Retrieve the Lost Artifact of %{region}", description: "A powerful artifact has been lost in the wilds of %{region}. Retrieve it before the enemy does." },
    { title: "Defend the Village near %{region}", description: "Orcs threaten a small settlement near %{region}. Rally the defense." },
    { title: "Hunt the Warg Pack in %{region}", description: "A pack of Wargs has been terrorizing travelers near %{region}." },
    { title: "Explore the Ruins of %{region}", description: "Ancient ruins have been discovered near %{region}. Investigate their secrets." },
    { title: "Deliver a Message to %{region}", description: "An urgent message must reach the leaders in %{region} before it's too late." }
  ].freeze

  RANDOM_REGIONS = [
    "The Shire", "Rivendell", "Mirkwood", "Rohan", "Gondor",
    "Mordor", "Isengard", "Fangorn", "Erebor", "Lothlorien"
  ].freeze

  def generate_random_quest
    template = RANDOM_QUEST_TEMPLATES.sample
    region = RANDOM_REGIONS.sample
    danger_level = rand(1..10)

    Quest.create!(
      title: format(template[:title], region: region),
      description: format(template[:description], region: region),
      status: :pending,
      danger_level: danger_level,
      region: region,
      quest_type: :random,
      campaign_order: nil,
      progress: 0.0,
      attempts: 0
    )
  end

  def rand_progress(min, max)
    min = min.to_f
    max = max.to_f
    min + rand * (max - min)
  end

  PROGRESS_MESSAGES = [
    "The party presses onward through dangerous territory.",
    "Progress is slow but steady as the company advances.",
    "The fellowship encounters resistance but pushes through.",
    "A brief rest, then the march continues.",
    "The path grows darker, but courage holds.",
    "Scouts report the objective draws nearer.",
    "The party overcomes an obstacle on the road.",
    "Weary but determined, the company continues."
  ].freeze

  def generate_progress_message(quest)
    "#{quest.title}: #{PROGRESS_MESSAGES.sample}"
  end

  # Broadcast the most recent quest event over Action Cable.
  def broadcast_quest_update(quest, event_type)
    event = quest.quest_events.order(created_at: :desc).first
    QuestEventBroadcaster.broadcast(event) if event
  end
end
