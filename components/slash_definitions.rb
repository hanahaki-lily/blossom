# frozen_string_literal: true

# ==========================================
# Blossom slash command SCHEMA for Discord bulk registration.
# Command handlers remain in commands/** via $bot.application_command(...)
#
# Regenerate from slash_registry.rb (=begin block): ruby components/_gen_slash_definitions.rb
# ==========================================

module BlossomSlashDefinitions
  module_function

  # Builds the PUT /applications/{id}/commands payload (bulk overwrite).
  def global_application_commands
    cmds = []
    slash_cmd = proc do |name, description, type: :chat_input, default_member_permissions: nil, contexts: nil, nsfw: nil, &blk|
      t = Discordrb::ApplicationCommand::TYPES[type] || type
      b = Discordrb::Interactions::OptionBuilder.new
      blk&.call(b)
      row = {
        'name' => name.to_s,
        'description' => description.to_s,
        'type' => t.to_i,
        'options' => JSON.parse(JSON.generate(b.to_a))
      }
      row['default_member_permissions'] = default_member_permissions unless default_member_permissions.nil?
      row['contexts'] = contexts unless contexts.nil?
      row['nsfw'] = nsfw unless nsfw.nil?
      cmds << row
    end

    # =========================
    # CORE & UTILITY
    # =========================
    
    slash_cmd.call(:ping, 'Check bot latency')
    slash_cmd.call(:help, 'Shows a paginated list of all available commands')
    slash_cmd.call(:about, 'Learn more about Blossom and her creator!')
    slash_cmd.call(:support, 'Get a link to the official support server')
    slash_cmd.call(:premium, 'View the benefits of Blossom Premium!')
    slash_cmd.call(:serverinfo, 'Displays information about the current server')
    slash_cmd.call(:suggest, 'Send a suggestion directly to the developer!') do |cmd|
      cmd.string('suggestion', 'What would you like to see added or changed?', required: true)
    end
    slash_cmd.call(:stats, 'View your lifetime stats dashboard')
    slash_cmd.call(:notifications, 'Set how achievement notifications are delivered') do |cmd|
      cmd.string('mode', 'Notification mode', required: true, choices: { 'Channel' => 'channel', 'DM' => 'dm', 'Silent' => 'silent' })
    end
    slash_cmd.call(:challenges, 'View and claim weekly challenges')
    slash_cmd.call(:profile, 'Customize your premium profile') do |cmd|
      cmd.subcommand(:view, 'View your current profile settings')
      cmd.subcommand(:shop, 'Cosmetic shop — Prisma prices and equip commands')
      cmd.subcommand(:color, 'Set your profile color') do |sub|
        sub.string('hex', 'Hex color code (e.g. FF00AA)', required: true)
      end
      cmd.subcommand(:bio, 'Set your profile bio') do |sub|
        sub.string('text', 'Your bio text (max 100 characters)', required: true)
      end
      cmd.subcommand(:fav, 'Set a favorite character on your profile') do |sub|
        sub.integer('slot', 'Slot number', required: true, choices: { 'Slot 1' => 1, 'Slot 2' => 2, 'Slot 3' => 3, 'Slot 4' => 4, 'Slot 5' => 5 })
        sub.string('character', 'Name of the character you own', required: true)
      end
      cmd.subcommand(:unfav, 'Remove a favorite character from a slot') do |sub|
        sub.integer('slot', 'Slot number', required: true, choices: { 'Slot 1' => 1, 'Slot 2' => 2, 'Slot 3' => 3, 'Slot 4' => 4, 'Slot 5' => 5 })
      end
      cmd.subcommand(:pet, 'Equip or view available pets') do |sub|
        sub.string('id', 'Pet ID to equip, or "none" to unequip (leave blank to browse)', required: false)
      end
      cmd.subcommand(:title, 'Equip or view available titles') do |sub|
        sub.string('id', 'Title ID to equip, or "none" to unequip (leave blank to browse)', required: false)
      end
      cmd.subcommand(:theme, 'Apply a collection theme') do |sub|
        sub.string('id', 'Theme ID to apply (leave blank to browse)', required: false)
      end
      cmd.subcommand(:badge, 'Equip or view badges') do |sub|
        sub.string('id', 'Badge ID to equip, or "none" to unequip (leave blank to browse)', required: false)
      end
      cmd.subcommand(:epithet, 'Short line next to your name on leaderboards (max 24)') do |sub|
        sub.string('text', 'Text, or "clear" to remove', required: true)
      end
      cmd.subcommand(:tagline, 'Extra flair line on balance / level (max 120)') do |sub|
        sub.string('text', 'Text, or "clear" to remove', required: true)
      end
      cmd.subcommand(:reset, 'Reset all profile customizations to default')
    end
    
    # =========================
    # FUN & SOCIAL
    # =========================
    
    slash_cmd.call(:kettle, 'Pings a specific user with a yay emoji')
    slash_cmd.call(:interactions, 'Show your hug/slap stats')
    slash_cmd.call(:hug, 'Send a hug with a random GIF') do |cmd|
      cmd.user('user', 'The person you want to hug', required: true)
    end
    slash_cmd.call(:slap, 'Send a playful slap with a random GIF') do |cmd|
      cmd.user('user', 'The person you want to slap', required: true)
    end
    slash_cmd.call(:pat, 'Give someone a gentle head pat') do |cmd|
      cmd.user('user', 'The person you want to pat', required: true)
    end
    slash_cmd.call(:rep, 'Give reputation to another user') do |cmd|
      cmd.user('user', 'Who deserves some rep?', required: true)
    end
    slash_cmd.call(:marry, 'Propose to another user!') do |cmd|
      cmd.user('user', 'The love of your life', required: true)
    end
    slash_cmd.call(:divorce, 'End your marriage')
    slash_cmd.call(:birthday, 'Set your birthday for a special reward') do |cmd|
      cmd.string('date', 'Your birthday in MM/DD format', required: true)
    end
    slash_cmd.call(:friends, 'View friendships and affinity') do |cmd|
      cmd.user('user', 'Optional: inspect friendship with this user', required: false)
    end
    slash_cmd.call(:crew, 'Create and manage your crew (use prefix for create/invite/kick)') do |cmd|
      cmd.string('action', 'e.g. info, leaderboard, leave, disband', required: false)
    end
    
    # =========================
    # ECONOMY
    # =========================
    
    slash_cmd.call(:balance, "Show a user's coin balance, gacha stats, and inventory") do |cmd|
      cmd.user('user', 'The user to check (optional)', required: false)
    end
    slash_cmd.call(:daily, 'Claim your daily coin reward')
    slash_cmd.call(:work, 'Work for some coins')
    slash_cmd.call(:stream, 'Go live and earn some coins!')
    slash_cmd.call(:post, 'Post on social media for some quick coins!')
    slash_cmd.call(:collab, 'Ask the server to do a collab stream! (30m cooldown)')
    slash_cmd.call(:cooldowns, 'Check your active timers for economy commands')
    slash_cmd.call(:givecoins, 'Give your coins to another user') do |cmd|
      cmd.user('user', 'Who?', required: true)
      cmd.integer('amount', 'How much?', required: true)
    end
    slash_cmd.call(:remindme, 'Toggle your daily reward reminder ping')
    slash_cmd.call(:vote, 'top.gg: Prisma rewards & vote reminder DMs') do |cmd|
      cmd.string('action', 'Info or toggle reminders', required: false, choices: { 'Info & link' => 'info', 'Toggle reminder DMs' => 'remind' })
    end
    slash_cmd.call(:event, 'Open the Limited Time Event Hub!')
    slash_cmd.call(:vipcrate, 'Claim your monthly subscriber VIP crate (Premium)')
    slash_cmd.call(:eventvip, 'Daily bonus event currency during seasonal events (Premium)')
    slash_cmd.call(:invest, 'Invest coins for passive returns (Premium)') do |cmd|
      cmd.integer('amount', 'Amount to invest (minimum 1,000)', required: true)
    end
    slash_cmd.call(:portfolio, 'View your investment portfolio (Premium)')
    slash_cmd.call(:withdraw, 'Cash out your investment (Premium)')
    slash_cmd.call(:autoclaim, 'Toggle automatic daily claims (Premium)')
    slash_cmd.call(:leaderboard, 'Show top users by level for this server')
    slash_cmd.call(:level, 'Show a user\'s level and XP for this server') do |cmd|
      cmd.user('user', 'The user to check (optional)', required: false)
    end
    slash_cmd.call(:lottery, 'Enter the hourly global lottery!') do |cmd|
      cmd.integer('tickets', 'How many 1000-coin tickets to buy', required: false)
    end
    slash_cmd.call(:lotteryinfo, 'View current lottery stats and your tickets')
    
    # =========================
    # ARCADE
    # =========================
    
    slash_cmd.call(:coinflip, 'Bet your stream revenue on a coinflip!') do |cmd|
      cmd.integer('amount', 'How many coins to bet', required: true)
      cmd.string('choice', 'Heads or Tails', required: true, choices: { 'Heads' => 'heads', 'Tails' => 'tails' })
    end
    slash_cmd.call(:slots, 'Spin the neon slots!') do |cmd|
      cmd.integer('amount', 'How many coins to bet', required: true)
    end
    slash_cmd.call(:roulette, 'Bet on the roulette wheel!') do |cmd|
      cmd.integer('amount', 'How many coins to bet', required: true)
      cmd.string('bet', 'red, black, even, odd, or 0-36', required: true)
    end
    slash_cmd.call(:scratch, 'Buy a neon scratch-off ticket for 500 coins!')
    slash_cmd.call(:dice, 'Roll 2d6! Bet on high (8-12), low (2-6), or 7.') do |cmd|
      cmd.integer('amount', 'How many coins to bet', required: true)
      cmd.string('bet', 'high, low, or 7', required: true, choices: { 'High (8-12)' => 'high', 'Low (2-6)' => 'low', 'Seven (7)' => '7' })
    end
    slash_cmd.call(:cups, 'Guess which cup hides the coin (1, 2, or 3)!') do |cmd|
      cmd.integer('amount', 'How many coins to bet', required: true)
      cmd.integer('guess', 'Cup 1, 2, or 3', required: true, choices: { 'Cup 1' => 1, 'Cup 2' => 2, 'Cup 3' => 3 })
    end
    slash_cmd.call(:blackjack, 'Play blackjack against Blossom!') do |cmd|
      cmd.integer('amount', 'How many coins to bet', required: true)
    end
    slash_cmd.call(:spin, 'Spin the daily prize wheel!')
    slash_cmd.call(:rps, 'Challenge someone to Rock Paper Scissors!') do |cmd|
      cmd.user('user', 'Who do you want to challenge?', required: true)
      cmd.integer('bet', 'How many coins to bet', required: true)
    end
    slash_cmd.call(:fish, 'Cast a line and catch something!')
    slash_cmd.call(:trivia, 'Answer VTuber trivia for coins!')
    slash_cmd.call(:boss, 'View and attack the monthly boss!')
    slash_cmd.call(:bosssetup, 'Set boss defeat announcement channel (Admin)') do |cmd|
      cmd.channel('channel', 'Announcement channel (omit for usage)', required: false)
    end
    
    # =========================
    # GACHA & INVENTORY
    # =========================
    
    slash_cmd.call(:summon, 'Roll the gacha!')
    slash_cmd.call(:collection, 'View all the characters you own') do |cmd|
      cmd.user('user', 'The user whose collection you want to view', required: false)
    end
    slash_cmd.call(:custombanner, 'Set a custom pull banner for 1 hour (Premium, 20 Prisma)') do |cmd|
      cmd.string('commons', '5 common characters (comma-separated)', required: true)
      cmd.string('rares', '5 rare characters (comma-separated)', required: true)
      cmd.string('legendaries', '5 legendary characters (comma-separated)', required: true)
      cmd.string('goddesses', '3 goddess characters (comma-separated)', required: true)
    end
    slash_cmd.call(:shop, 'View the character shop and direct-buy prices!')
    slash_cmd.call(:buy, 'Buy a Black Market item or shop character') do |cmd|
      cmd.string('item', 'Item or character name', required: true, autocomplete: true)
      cmd.integer('quantity', 'Quantity (stackables)', required: false)
    end
    slash_cmd.call(:view, 'View any VTuber character in detail') do |cmd|
      cmd.string('character', 'Name of the character', required: true, autocomplete: true)
    end
    slash_cmd.call(:ascend, 'Fuse 5 duplicate characters into a Shiny Ascended version!') do |cmd|
      cmd.string('character', 'Name of the character', required: true)
    end
    slash_cmd.call(:trade, 'Trade a character with someone') do |cmd|
      cmd.user('user', 'The user you want to trade with', required: true)
      cmd.string('offer', 'The character you are giving', required: true)
      cmd.string('request', 'The character you want from them', required: true)
    end
    slash_cmd.call(:givecard, 'Give a VTuber card to another user') do |cmd|
      cmd.user('user', 'The user you want to give the card to', required: true)
      cmd.string('character', 'The name of the character', required: true)
    end
    slash_cmd.call(:sell, 'Sell your duplicate VTuber cards for coins') do |cmd|
      cmd.string('filter', 'How do you want to sell?', required: true, choices: {
        'All Dupes (Keep 1 of each)' => 'all',
        'Over 5 (Save copies for ascending)' => 'over5',
        'Specific Rarity' => 'rarity'
      })
      cmd.string('rarity', 'If filtering by rarity, which one?', required: false, choices: {
        'Common' => 'common', 'Rare' => 'rare', 'Legendary' => 'legendary', 'Goddess' => 'goddess'
      })
    end
    slash_cmd.call(:autosell, 'Toggle auto-sell for common dupes (Premium)')
    slash_cmd.call(:shinymode, 'Toggle Shiny Hunting Mode — 2x cost, 2% shiny (Premium)')
    slash_cmd.call(:giftlog, 'View your card gifting history') do |cmd|
      cmd.integer('page', 'Page number', required: false)
    end
    slash_cmd.call(:craft, 'Craft exclusive cosmetics from materials') do |cmd|
      cmd.string('recipe', 'Recipe id (omit to browse recipes)', required: false)
    end
    slash_cmd.call(:salvage, 'Break down duplicate cards into crafting materials') do |cmd|
      cmd.integer('amount', 'Number of cards', required: false)
      cmd.string('rarity', 'Only salvage this rarity', required: false, choices: {
        'Common' => 'common', 'Rare' => 'rare', 'Legendary' => 'legendary', 'Goddess' => 'goddess'
      })
    end
    
    # =========================
    # ADMINISTRATION
    # =========================
    
    slash_cmd.call(:giveaway, 'Start a giveaway (Admin only)') do |cmd|
      cmd.channel('channel', 'The channel to host the giveaway in', required: true)
      cmd.string('time', 'Duration (e.g., 10m, 2h, 1d)', required: true)
      cmd.string('prize', 'What are you giving away?', required: true)
    end
    slash_cmd.call(:bomb, 'Enable or disable bomb drops (Admin Only)') do |cmd|
      cmd.string('action', 'Enable or disable', required: true, choices: { 'Enable' => 'enable', 'Disable' => 'disable' })
      cmd.channel('channel', 'The channel to drop bombs in (required for enable)', required: false)
    end
    slash_cmd.call(:setxp, 'Manage user XP/Level — add, remove, set, or level (Admin Only)') do |cmd|
      cmd.string('action', 'What to do', required: true, choices: { 'Add XP' => 'add', 'Remove XP' => 'remove', 'Set XP' => 'set', 'Set Level' => 'level' })
      cmd.user('user', 'The user to modify', required: true)
      cmd.integer('amount', 'Amount of XP or target level', required: true)
    end
    slash_cmd.call(:levelup, 'Configure where level-up messages go (Admin Only)') do |cmd|
      cmd.string('state', 'Turn messages on or off', required: false, choices: { 'On' => 'on', 'Off' => 'off' })
      cmd.channel('channel', 'Pick a specific channel for the messages', required: false)
    end
    slash_cmd.call(:purge, 'Deletes a number of messages (Admin only)') do |cmd|
      cmd.integer('amount', 'Number of messages to delete (1-100)', required: true)
    end
    slash_cmd.call(:kick, 'Kicks a user from the server (Admin only)') do |cmd|
      cmd.user('user', 'The user to kick', required: true)
      cmd.string('reason', 'Why are they being kicked?', required: false)
    end
    slash_cmd.call(:ban, 'Bans a user from the server (Admin only)') do |cmd|
      cmd.user('user', 'The user to ban', required: true)
      cmd.string('reason', 'Why are they being banned?', required: false)
    end
    slash_cmd.call(:timeout, 'Timeouts a user for X minutes (Admin only)') do |cmd|
      cmd.user('user', 'The user to timeout', required: true)
      cmd.integer('minutes', 'How many minutes?', required: true)
      cmd.string('reason', 'Why are they being timed out?', required: false)
    end
    slash_cmd.call(:logsetup, 'Set the channel for server logs (Admin Only)') do |cmd|
      cmd.channel('channel', 'The channel to send logs to', required: true)
    end
    slash_cmd.call(:logtoggle, 'Toggle logging for specific events (Admin Only)') do |cmd|
      cmd.string('type', 'What to toggle', required: true, choices: {
        'Message Deletes' => 'deletes', 'Message Edits' => 'edits', 'Mod Actions' => 'mod',
        'DM Mods' => 'dms', 'Member Joins' => 'joins', 'Member Leaves' => 'leaves'
      })
    end
    slash_cmd.call(:welcomer, 'Enable or disable the welcome message system (Admin Only)') do |cmd|
      cmd.string('action', 'Enable or disable', required: true, choices: { 'Enable' => 'enable', 'Disable' => 'disable' })
      cmd.channel('channel', 'The channel to send welcome messages to (required for enable)', required: false)
    end
    slash_cmd.call(:verifysetup, 'Set up a verification panel (Admin Only)') do |cmd|
      cmd.channel('channel', 'The channel to send the panel to', required: true)
      cmd.role('role', 'The role to give verified members', required: true)
    end
    slash_cmd.call(:achievements, 'Toggle achievement notifications for this server (Admin Only)')
    slash_cmd.call(:heist, 'Configure hourly heist events (Admin)') do |cmd|
      cmd.string('action', 'setup or disable', required: false, choices: { 'Setup' => 'setup', 'Disable' => 'disable' })
      cmd.channel('channel', 'Channel for heists (required for setup)', required: false)
    end
    slash_cmd.call(:automod, 'Configure auto-moderation (Admin)') do |cmd|
      cmd.string('action', 'Omit for status', required: false, choices: {
        'Toggle link filter' => 'links', 'Toggle spam filter' => 'spam', 'Banned words' => 'words'
      })
      cmd.string('subaction', 'For words: add / remove / list', required: false, choices: { 'Add' => 'add', 'Remove' => 'remove', 'List' => 'list' })
      cmd.string('word', 'Word (for add/remove)', required: false)
    end
    slash_cmd.call(:tipsetup, 'Set daily tip channel (Admin)') do |cmd|
      cmd.channel('channel', 'Channel for tips (omit to disable or see usage)', required: false)
    end
    slash_cmd.call(:commleveltoggle, 'Toggle community level-up announcements')
    
    # Developer commands stay prefix-only (see CHANGELOG).
    names = cmds.map { |c| c['name'] }
    dups = names.tally.reject { |_n, c| c == 1 }.keys
    raise "Duplicate slash command names: #{dups.join(',')}" if dups.any?

    cmds
  end
end
