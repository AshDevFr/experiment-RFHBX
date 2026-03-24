# frozen_string_literal: true

# QuestAutoStartWorker is responsible for starting the next available quest
# immediately when no quest is currently in progress. It is triggered:
#
#   1. On Sidekiq startup (boot-time safety net)
#   2. After a quest completes successfully (via QuestTickWorker)
#   3. As a sidekiq-cron safety-net job (every 5 minutes)
#
# The worker is idempotent: if a quest is already active for the current mode,
# it exits immediately without doing any work. A short-lived Redis lock prevents
# duplicate activations when multiple instances run concurrently.
class QuestAutoStartWorker
  include Sidekiq::Worker

  sidekiq_options queue: :critical, retry: 3

  # Redis key / TTL for the distributed idempotency lock.
  LOCK_KEY = "quest_auto_start_lock"
  LOCK_TTL = 30 # seconds

  def perform
    config = SimulationConfig.current
    return unless config.running?

    # Fast path: skip if a quest is already active for the current mode.
    return if active_quest_for_mode?(config)

    # Acquire a short-lived distributed lock so that concurrent calls (e.g. on
    # a multi-threaded Sidekiq server) don't race to start the same quest.
    acquired = Sidekiq.redis { |r| r.set(LOCK_KEY, 1, nx: true, ex: LOCK_TTL) }
    return unless acquired

    begin
      if config.campaign?
        advance_campaign(config)
      else
        ensure_random_quest(config)
      end
    ensure
      Sidekiq.redis { |r| r.del(LOCK_KEY) }
    end
  end

  private

  # Returns true when there is already an active quest in the mode that is
  # currently selected, meaning no action is needed.
  def active_quest_for_mode?(config)
    if config.campaign?
      Quest.where(quest_type: :campaign, status: :active).exists?
    else
      Quest.where(quest_type: :random, status: :active).exists?
    end
  end

  # Activates the next pending campaign quest, or switches to random mode when
  # all campaign quests have been completed.
  def advance_campaign(config)
    # Guard: a campaign quest may have been started between the fast-path check
    # and lock acquisition.
    return if Quest.where(quest_type: :campaign, status: :active).exists?

    next_quest = Quest.where(quest_type: :campaign)
                      .where.not(status: :completed)
                      .order(:campaign_order)
                      .first

    if next_quest
      activate_campaign_quest(next_quest, config)
    else
      # All campaign quests are done — switch to random mode and immediately
      # start the first random quest so there is no idle period.
      config.update!(mode: :random)
      ensure_random_quest(config)
    end
  end

  # Sets up party memberships, transitions the quest to :active, and broadcasts
  # the started event.
  def activate_campaign_quest(quest, config)
    if quest.quest_memberships.empty?
      idle_characters = Character.where(status: :idle).limit(4)
      idle_characters.each do |character|
        QuestMembership.find_or_create_by!(quest: quest, character: character) do |m|
          m.role = "Adventurer"
        end
      end
    end

    quest.characters.each { |character| character.update!(status: :on_quest) }
    quest.update!(status: :active, progress: 0.0)
    config.update!(campaign_position: quest.campaign_order || 0)

    event = QuestEvent.create!(
      quest: quest,
      event_type: :started,
      message: "#{quest.title} has begun!",
      data: { party: quest.characters.pluck(:name) }
    )

    QuestEventBroadcaster.broadcast(event)
  end

  # Generates a new random quest and assigns idle characters if at least two are
  # available.
  def ensure_random_quest(config) # rubocop:disable Lint/UnusedMethodArgument
    # Guard: a random quest may have been started between the fast-path check
    # and lock acquisition.
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

    event = QuestEvent.create!(
      quest: quest,
      event_type: :started,
      message: "#{quest.title} has begun with a party of #{party.count}!",
      data: { party: party.pluck(:name) }
    )

    QuestEventBroadcaster.broadcast(event)
  end

  RANDOM_QUEST_TEMPLATES = [
    { title: "Patrol the Borders of %{region}",
      description: "Scout the perimeter of %{region} for signs of enemy activity." },
    { title: "Clear the Caves of %{region}",
      description: "Purge the dark creatures lurking in the caves near %{region}." },
    { title: "Escort the Merchant to %{region}",
      description: "Safely escort a merchant caravan through dangerous territory to %{region}." },
    { title: "Retrieve the Lost Artifact of %{region}",
      description: "A powerful artifact has been lost in the wilds of %{region}. Retrieve it before the enemy does." },
    { title: "Defend the Village near %{region}",
      description: "Orcs threaten a small settlement near %{region}. Rally the defense." },
    { title: "Hunt the Warg Pack in %{region}",
      description: "A pack of Wargs has been terrorizing travelers near %{region}." },
    { title: "Explore the Ruins of %{region}",
      description: "Ancient ruins have been discovered near %{region}. Investigate their secrets." },
    { title: "Deliver a Message to %{region}",
      description: "An urgent message must reach the leaders in %{region} before it's too late." }
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
end
