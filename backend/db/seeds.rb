# frozen_string_literal: true

# =============================================================================
# Mordor's Edge — Seed Data
# =============================================================================
#
# Structure:
#   1. Characters  — 25 LOTR characters with stats, race, realm, title, status
#   2. Quests      — 10 canonical quests in campaign_order with danger levels
#   3. Artifacts   — 16 notable items with stat_bonus jsonb and corrupted flag
#   4. SimulationConfig  — singleton config, running: false (clean blank state)
#
# Idempotency: every record uses find_or_create_by!(name:) so running
# `rails db:seed` twice is safe — no duplicates will be created.
#
# Clean-state guarantee: no QuestMembership records are created by seeds.
# All quests start as pending with 0 progress. SimulationConfig defaults to
# running: false. When the simulation is started (running: true), the
# QuestAutoStartWorker and QuestTickWorker automatically detect pending quests
# and auto-assign idle heroes to form a party.
#
# To extend: add entries to the arrays below and re-run `rails db:seed`.
# =============================================================================

ActiveRecord::Base.transaction do
  # ---------------------------------------------------------------------------
  # 1. Characters
  # ---------------------------------------------------------------------------
  puts "Seeding characters..."

  characters_data = [
    # ── The Fellowship ──────────────────────────────────────────────────────
    {
      name: "Frodo Baggins",
      race: "Hobbit",
      realm: "The Shire",
      title: "Ring Bearer",
      ring_bearer: true,
      status: "idle",
      strength: 5,
      wisdom: 14,
      endurance: 12
    },
    {
      name: "Samwise Gamgee",
      race: "Hobbit",
      realm: "The Shire",
      title: "Mayor of the Shire",
      ring_bearer: false,
      status: "idle",
      strength: 7,
      wisdom: 10,
      endurance: 16
    },
    {
      name: "Aragorn",
      race: "Human",
      realm: "Gondor",
      title: "King Elessar",
      ring_bearer: false,
      status: "idle",
      strength: 17,
      wisdom: 15,
      endurance: 16
    },
    {
      name: "Gandalf",
      race: "Maiar",
      realm: "Valinor",
      title: "The White",
      ring_bearer: false,
      status: "idle",
      strength: 14,
      wisdom: 20,
      endurance: 15
    },
    {
      name: "Legolas",
      race: "Elf",
      realm: "Woodland Realm",
      title: "Prince of Mirkwood",
      ring_bearer: false,
      status: "idle",
      strength: 18,
      wisdom: 13,
      endurance: 18
    },
    {
      name: "Gimli",
      race: "Dwarf",
      realm: "Erebor",
      title: "Lord of the Glittering Caves",
      ring_bearer: false,
      status: "idle",
      strength: 16,
      wisdom: 10,
      endurance: 17
    },
    {
      name: "Boromir",
      race: "Human",
      realm: "Gondor",
      title: "Captain of the White Tower",
      ring_bearer: false,
      status: "fallen",
      strength: 18,
      wisdom: 9,
      endurance: 15
    },
    {
      name: "Pippin",
      race: "Hobbit",
      realm: "The Shire",
      title: "Guard of the Citadel",
      ring_bearer: false,
      status: "idle",
      strength: 5,
      wisdom: 7,
      endurance: 11
    },
    {
      name: "Merry",
      race: "Hobbit",
      realm: "The Shire",
      title: "Knight of Rohan",
      ring_bearer: false,
      status: "idle",
      strength: 6,
      wisdom: 9,
      endurance: 12
    },
    # ── Extended cast ────────────────────────────────────────────────────────
    {
      name: "Eowyn",
      race: "Human",
      realm: "Rohan",
      title: "Shieldmaiden of Rohan",
      ring_bearer: false,
      status: "idle",
      strength: 14,
      wisdom: 11,
      endurance: 13
    },
    {
      name: "Faramir",
      race: "Human",
      realm: "Gondor",
      title: "Prince of Ithilien",
      ring_bearer: false,
      status: "idle",
      strength: 14,
      wisdom: 16,
      endurance: 13
    },
    {
      name: "Galadriel",
      race: "Elf",
      realm: "Lothlorien",
      title: "Lady of Light",
      ring_bearer: false,
      status: "idle",
      strength: 10,
      wisdom: 20,
      endurance: 14
    },
    {
      name: "Elrond",
      race: "Elf",
      realm: "Rivendell",
      title: "Lord of Rivendell",
      ring_bearer: false,
      status: "idle",
      strength: 12,
      wisdom: 19,
      endurance: 14
    },
    {
      name: "Saruman",
      race: "Maiar",
      realm: "Isengard",
      title: "The White (fallen)",
      ring_bearer: false,
      status: "fallen",
      strength: 13,
      wisdom: 18,
      endurance: 12
    },
    {
      name: "Sauron",
      race: "Maiar",
      realm: "Mordor",
      title: "The Dark Lord",
      ring_bearer: false,
      status: "fallen",
      strength: 20,
      wisdom: 17,
      endurance: 20
    },
    {
      name: "Tom Bombadil",
      race: "Unknown",
      realm: "Old Forest",
      title: "Master of Wood, Water, and Hill",
      ring_bearer: false,
      status: "idle",
      strength: 15,
      wisdom: 20,
      endurance: 18
    },
    {
      name: "Goldberry",
      race: "Unknown",
      realm: "Old Forest",
      title: "River-daughter",
      ring_bearer: false,
      status: "idle",
      strength: 8,
      wisdom: 17,
      endurance: 12
    },
    {
      name: "Glorfindel",
      race: "Elf",
      realm: "Rivendell",
      title: "Lord of the House of the Golden Flower",
      ring_bearer: false,
      status: "idle",
      strength: 19,
      wisdom: 16,
      endurance: 18
    },
    {
      name: "Beregond",
      race: "Human",
      realm: "Gondor",
      title: "Guard of the Citadel",
      ring_bearer: false,
      status: "idle",
      strength: 12,
      wisdom: 10,
      endurance: 13
    },
    {
      name: "Farmer Maggot",
      race: "Hobbit",
      realm: "The Shire",
      title: "Farmer of Bamfurlong",
      ring_bearer: false,
      status: "idle",
      strength: 6,
      wisdom: 8,
      endurance: 10
    },
    {
      name: "Ghân-buri-Ghân",
      race: "Wild Man",
      realm: "Druadan Forest",
      title: "Chieftain of the Woses",
      ring_bearer: false,
      status: "idle",
      strength: 10,
      wisdom: 13,
      endurance: 14
    },
    {
      name: "Radagast",
      race: "Maiar",
      realm: "Rhosgobel",
      title: "The Brown",
      ring_bearer: false,
      status: "idle",
      strength: 8,
      wisdom: 15,
      endurance: 10
    },
    {
      name: "Quickbeam",
      race: "Ent",
      realm: "Fangorn",
      title: "Hastiest of Ents",
      ring_bearer: false,
      status: "idle",
      strength: 17,
      wisdom: 12,
      endurance: 19
    },
    {
      name: "Treebeard",
      race: "Ent",
      realm: "Fangorn",
      title: "Eldest of Ents",
      ring_bearer: false,
      status: "idle",
      strength: 18,
      wisdom: 16,
      endurance: 20
    },
    {
      name: "Shelob",
      race: "Creature",
      realm: "Cirith Ungol",
      title: "Last Child of Ungoliant",
      ring_bearer: false,
      status: "idle",
      strength: 18,
      wisdom: 5,
      endurance: 16
    }
  ]

  characters_data.each do |attrs|
    Character.find_or_create_by!(name: attrs[:name]) do |c|
      c.assign_attributes(attrs)
    end
  end

  puts "  #{Character.count} characters present."

  # ---------------------------------------------------------------------------
  # 2. Quests
  # ---------------------------------------------------------------------------
  puts "Seeding quests..."

  # All quests are seeded as pending with 0 progress and 0 attempts.
  # The simulation workers (QuestTickWorker / QuestAutoStartWorker) will
  # activate them in campaign_order and auto-assign idle heroes when the
  # simulation is started.
  quests_data = [
    {
      title: "Escape the Old Forest",
      description: "Navigate the treacherous Old Forest and seek refuge with Tom Bombadil.",
      status: "pending",
      danger_level: 4,
      region: "Old Forest",
      quest_type: "campaign",
      campaign_order: 1,
      progress: 0.0,
      attempts: 0
    },
    {
      title: "Hunt for Gollum",
      description: "Track down Gollum across the Wilderland to learn the truth of the One Ring.",
      status: "pending",
      danger_level: 6,
      region: "Wilderness",
      quest_type: "campaign",
      campaign_order: 2,
      progress: 0.0,
      attempts: 0
    },
    {
      title: "Destroy the One Ring",
      description: "Bear the One Ring into the heart of Mordor and cast it into the fires of Mount Doom.",
      status: "pending",
      danger_level: 10,
      region: "Mordor",
      quest_type: "campaign",
      campaign_order: 3,
      progress: 0.0,
      attempts: 0
    },
    {
      title: "Retake Moria",
      description: "Attempt to reclaim the ancient dwarven halls of Khazad-dûm from the Balrog and Orcs.",
      status: "pending",
      danger_level: 9,
      region: "Moria",
      quest_type: "campaign",
      campaign_order: 4,
      progress: 0.0,
      attempts: 0
    },
    {
      title: "Defend Helm's Deep",
      description: "Hold the fortress of Helm's Deep against Saruman's ten-thousand-strong Uruk-hai army.",
      status: "pending",
      danger_level: 8,
      region: "Rohan",
      quest_type: "campaign",
      campaign_order: 5,
      progress: 0.0,
      attempts: 0
    },
    {
      title: "March of the Ents",
      description: "Lead the Ents of Fangorn Forest to tear down Isengard and break Saruman's power.",
      status: "pending",
      danger_level: 7,
      region: "Isengard",
      quest_type: "campaign",
      campaign_order: 6,
      progress: 0.0,
      attempts: 0
    },
    {
      title: "Passage of the Paths of the Dead",
      description: "Summon the Dead Men of Dunharrow to fulfill their oath and turn the tide at Pelargir.",
      status: "pending",
      danger_level: 8,
      region: "White Mountains",
      quest_type: "campaign",
      campaign_order: 7,
      progress: 0.0,
      attempts: 0
    },
    {
      title: "Rescue from Cirith Ungol",
      description: "Infiltrate the tower of Cirith Ungol to rescue Frodo from the Orc garrison.",
      status: "pending",
      danger_level: 9,
      region: "Mordor",
      quest_type: "campaign",
      campaign_order: 8,
      progress: 0.0,
      attempts: 0
    },
    {
      title: "Assault on the Black Gate",
      description: "Lead a desperate feint at Mordor's Black Gate to draw Sauron's Eye from the Ring-bearer.",
      status: "pending",
      danger_level: 9,
      region: "Mordor",
      quest_type: "campaign",
      campaign_order: 9,
      progress: 0.0,
      attempts: 0
    },
    {
      title: "Scouring of the Shire",
      description: "Drive Saruman's ruffians from the Shire and restore peace to the Hobbits' homeland.",
      status: "pending",
      danger_level: 5,
      region: "The Shire",
      quest_type: "campaign",
      campaign_order: 10,
      progress: 0.0,
      attempts: 0
    }
  ]

  quests_data.each do |attrs|
    Quest.find_or_create_by!(title: attrs[:title]) do |q|
      q.assign_attributes(attrs)
    end
  end

  puts "  #{Quest.count} quests present."

  # ---------------------------------------------------------------------------
  # 3. Artifacts
  # ---------------------------------------------------------------------------
  puts "Seeding artifacts..."

  frodo     = Character.find_by!(name: "Frodo Baggins")
  aragorn   = Character.find_by!(name: "Aragorn")
  gandalf   = Character.find_by!(name: "Gandalf")
  merry     = Character.find_by!(name: "Merry")
  galadriel = Character.find_by!(name: "Galadriel")
  elrond    = Character.find_by!(name: "Elrond")

  artifacts_data = [
    {
      name: "The One Ring",
      artifact_type: "Ring",
      power: "Grants invisibility to mortal wearers; corrupts the bearer; commands the other Rings of Power.",
      corrupted: true,
      character_id: frodo.id,
      stat_bonus: { "strength" => 5, "wisdom" => -3 }
    },
    {
      name: "Anduril (Flame of the West)",
      artifact_type: "Sword",
      power: "Reforged from the shards of Narsil; commands the allegiance of the Dead Men of Dunharrow.",
      corrupted: false,
      character_id: aragorn.id,
      stat_bonus: { "strength" => 4, "endurance" => 2 }
    },
    {
      name: "Narsil (shards)",
      artifact_type: "Sword",
      power: "Ancient blade of Elendil; cut the One Ring from Sauron's hand at the end of the Second Age.",
      corrupted: false,
      character_id: nil,
      stat_bonus: { "strength" => 2 }
    },
    {
      name: "Sting",
      artifact_type: "Sword",
      power: "Elvish blade that glows blue in the presence of Orcs.",
      corrupted: false,
      character_id: frodo.id,
      stat_bonus: { "strength" => 2, "endurance" => 1 }
    },
    {
      name: "Glamdring (Foe-hammer)",
      artifact_type: "Sword",
      power: "Ancient Elvish sword of Gondolin; glows in the presence of Orcs; wielded by Gandalf.",
      corrupted: false,
      character_id: gandalf.id,
      stat_bonus: { "strength" => 3, "wisdom" => 1 }
    },
    {
      name: "Orcrist (Goblin-cleaver)",
      artifact_type: "Sword",
      power: "Twin blade to Glamdring; placed upon Thorin Oakenshield's tomb as a sentinel.",
      corrupted: false,
      character_id: nil,
      stat_bonus: { "strength" => 3 }
    },
    {
      name: "Nenya (Ring of Adamant)",
      artifact_type: "Ring",
      power: "One of the Three Elven Rings; preserves and protects; worn by Galadriel.",
      corrupted: false,
      character_id: galadriel.id,
      stat_bonus: { "wisdom" => 4, "endurance" => 3 }
    },
    {
      name: "Vilya (Ring of Air)",
      artifact_type: "Ring",
      power: "Greatest of the Three Elven Rings; ring of air and sky; worn by Elrond.",
      corrupted: false,
      character_id: elrond.id,
      stat_bonus: { "wisdom" => 5, "endurance" => 2 }
    },
    {
      name: "Narya (Ring of Fire)",
      artifact_type: "Ring",
      power: "Ring of fire; kindles hearts with courage; worn by Gandalf.",
      corrupted: false,
      character_id: gandalf.id,
      stat_bonus: { "wisdom" => 3, "strength" => 1 }
    },
    {
      name: "Palantir of Orthanc",
      artifact_type: "Seeing Stone",
      power: "One of the seven Seeing Stones; corrupted by Sauron's will; used by Saruman and Pippin.",
      corrupted: true,
      character_id: nil,
      stat_bonus: { "wisdom" => 2, "endurance" => -2 }
    },
    {
      name: "Palantir of Minas Tirith",
      artifact_type: "Seeing Stone",
      power: "The Anor-stone; used by Denethor to survey Mordor's forces; eventually reclaimed by Aragorn.",
      corrupted: false,
      character_id: nil,
      stat_bonus: { "wisdom" => 3 }
    },
    {
      name: "Phial of Galadriel",
      artifact_type: "Light",
      power: "Contains the light of Eärendil's star; drives away darkness and great evil.",
      corrupted: false,
      character_id: frodo.id,
      stat_bonus: { "wisdom" => 2, "endurance" => 2 }
    },
    {
      name: "Mithril Coat",
      artifact_type: "Armor",
      power: "A shirt of Mithril rings; lighter than a feather, harder than steel — saved Frodo's life.",
      corrupted: false,
      character_id: frodo.id,
      stat_bonus: { "endurance" => 5 }
    },
    {
      name: "Horn of Gondor",
      artifact_type: "Horn",
      power: "Ancient war-horn of Gondor; its call cannot go unanswered within Gondor's borders.",
      corrupted: false,
      character_id: nil,
      stat_bonus: { "endurance" => 2, "strength" => 1 }
    },
    {
      name: "Red Book of Westmarch",
      artifact_type: "Book",
      power: "The chronicles of the War of the Ring, written by Bilbo and Frodo Baggins.",
      corrupted: false,
      character_id: nil,
      stat_bonus: { "wisdom" => 3 }
    },
    {
      name: "Barrow-blade (Merry's)",
      artifact_type: "Dagger",
      power: "Ancient blade of the Barrow-wights bearing a spell against the Nazgûl; helped slay the Witch-king.",
      corrupted: false,
      character_id: merry.id,
      stat_bonus: { "strength" => 2, "wisdom" => 1 }
    }
  ]

  artifacts_data.each do |attrs|
    Artifact.find_or_create_by!(name: attrs[:name]) do |a|
      a.assign_attributes(attrs)
    end
  end

  puts "  #{Artifact.count} artifacts present."

  # ---------------------------------------------------------------------------
  # 4. SimulationConfig — singleton config, clean blank state
  # ---------------------------------------------------------------------------
  # SimulationConfig.current creates the record with running: false by default.
  # Do NOT set running: true here — the app must start in a clean blank state.
  # Use the UI or API (updateSimulationConfig mutation) to start the simulation,
  # which will trigger QuestAutoStartWorker to assign idle heroes to quests.
  puts "Seeding simulation config..."

  sim_config = SimulationConfig.current

  puts "  SimulationConfig present (mode: #{sim_config.reload.mode}, running: #{sim_config.reload.running})."

  puts ""
  puts "Seed complete: #{Character.count} characters, #{Quest.count} quests, " \
       "#{Artifact.count} artifacts, 0 memberships (clean blank state — start simulation to begin)."
end
