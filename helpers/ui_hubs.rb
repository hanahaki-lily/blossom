# ==========================================
# HELPER: Interactive UI Builders (Hubs & Menus)
# DESCRIPTION: Generates the embeds and component views 
# for Blossom's general navigation tools.
# ==========================================

HELP_EMOJI_MAP = { 'Economy' => '💰', 'Gacha' => '🌟', 'Arcade' => '🕹️', 'Fun' => '🎉', 'Utility' => '🔧', 'Admin' => '🛡️' }.freeze
HELP_PER_PAGE = 5

# Blossom's category-specific remarks for the help menu
HELP_REMARKS = {
  'Home'     => "*You're staring at the menu like it's gonna order for you. Pick something already.*",
  'Economy'  => "*Grind coins, flex wealth, repeat. Welcome to capitalism, Neon Arcade edition.*",
  'Gacha'    => "*This is where your coins go to die. Don't say I didn't warn you, chat.*",
  'Arcade'   => "*Feeling lucky? Spoiler: you're probably not. But go off.*",
  'Fun'      => "*The chill zone. Hug your friends, slap your enemies, check your stats. Vibes only.*",
  'Utility'  => "*The boring-but-necessary stuff. You're welcome for organizing all of this, by the way.*",
  'Admin'    => "*Power tools for the people in charge. Don't break anything or I'm telling mom.*"
}.freeze

# Builds the raw CV2 select menu action row for the help menu dropdown.
def help_select_menu_raw(user_id)
  visible_categories = COMMAND_CATEGORIES.keys - ['Developer']

  options = [{ label: 'Home', value: 'Home', emoji: { name: '🏠' }, description: 'Back to the lobby~' }]
  visible_categories.each do |cat|
    options << { label: cat, value: cat, emoji: { name: HELP_EMOJI_MAP[cat] || '🌸' } }
  end

  {
    type: 1,
    components: [{
      type: 3,
      custom_id: "help_menu_#{user_id}",
      placeholder: 'Pick a category, I dare you...',
      max_values: 1,
      options: options
    }]
  }
end

# Builds pagination buttons for help pages
def help_page_buttons(user_id, category, page, total_pages)
  return nil if total_pages <= 1

  {
    type: 1,
    components: [
      { type: 2, custom_id: "helppg_#{user_id}_#{category}_#{page - 1}", label: '◀ Prev', style: 2, disabled: page <= 1 },
      { type: 2, custom_id: "helppg_noop", label: "#{page}/#{total_pages}", style: 2, disabled: true },
      { type: 2, custom_id: "helppg_#{user_id}_#{category}_#{page + 1}", label: 'Next ▶', style: 2, disabled: page >= total_pages }
    ]
  }
end

# Generates the full CV2 component array for a help page (container + select menu + pagination).
def help_cv2_components(bot, user_id, category, page = 1)
  remark = HELP_REMARKS[category] || HELP_REMARKS['Home']

  if category == 'Home'
    text_content = "Okay look, since you clearly need me to spell it out... welcome to the Neon Arcade. 🌸\n\n" \
                   "**Prefix:** `#{PREFIX}`\n" \
                   "*Everything works as Slash (`/`) or Prefix — I'm versatile like that.*\n\n" \
                   "Pick a category from the dropdown, or use `#{PREFIX}help <category>` to jump straight there.\n" \
                   "Categories: `economy`, `gacha`, `arcade`, `fun`, `utility`, `admin`"
    inner = [
      { type: 10, content: "## #{EMOJI_STRINGS['info']} Blossom Help Menu" },
      { type: 14, spacing: 1 },
      { type: 10, content: text_content },
      { type: 14, spacing: 1 },
      { type: 10, content: remark }
    ]

    mama_note = mom_remark(user_id, 'general')
    inner << { type: 10, content: mama_note } if mama_note

    [
      { type: 17, accent_color: NEON_COLORS.sample, components: inner },
      help_select_menu_raw(user_id)
    ]
  else
    cmds = COMMAND_CATEGORIES[category] || []
    total_pages = [(cmds.size / HELP_PER_PAGE.to_f).ceil, 1].max
    page = [[page, 1].max, total_pages].min

    start_idx = (page - 1) * HELP_PER_PAGE
    page_cmds = cmds[start_idx, HELP_PER_PAGE] || []

    cmd_lines = page_cmds.map do |cmd_sym|
      cmd = bot.commands[cmd_sym]
      desc = cmd ? (cmd.attributes[:description] || 'No description provided.') : 'No description provided.'
      aliases = cmd&.attributes&.dig(:aliases)
      alias_text = aliases && !aliases.empty? ? " *(#{aliases.map { |a| "`#{a}`" }.join(', ')})*" : ""
      "**`#{PREFIX}#{cmd_sym}`**#{alias_text}\n> #{desc}"
    end

    cat_emoji = HELP_EMOJI_MAP[category] || '🌸'
    text_content = cmd_lines.join("\n\n")

    inner = [
      { type: 10, content: "## #{cat_emoji} #{category} Commands" },
      { type: 14, spacing: 1 },
      { type: 10, content: text_content },
      { type: 14, spacing: 1 },
      { type: 10, content: remark }
    ]

    mama_note = mom_remark(user_id, 'general')
    inner << { type: 10, content: mama_note } if mama_note

    result = [{ type: 17, accent_color: NEON_COLORS.sample, components: inner }]

    # Add pagination buttons if needed
    page_btns = help_page_buttons(user_id, category, page, total_pages)
    result << page_btns if page_btns

    result << help_select_menu_raw(user_id)
    result
  end
end

def generate_category_embed(bot, user_obj, category)
  embed = Discordrb::Webhooks::Embed.new
  embed.color = NEON_COLORS.sample
  embed.timestamp = Time.now
  embed.footer = Discordrb::Webhooks::EmbedFooter.new(text: "Requested by #{user_obj.display_name}", icon_url: user_obj.avatar_url)

  remark = HELP_REMARKS[category] || HELP_REMARKS['Home']

  if category == 'Home'
    embed.title = "#{EMOJI_STRINGS['info']} Blossom Help Menu"
    embed.description = "Okay look, since you clearly need me to spell it out... welcome to the Neon Arcade. 🌸\n\n" \
                        "**Prefix:** `#{PREFIX}`\n" \
                        "*Everything works as Slash (`/`) or Prefix — I'm versatile like that.* \n\n" \
                        "Pick a category from the dropdown, or use `#{PREFIX}help <category>` to jump straight there.\n\n" \
                        "#{remark}#{mom_remark(user_obj.id, 'general')}"
  else
    embed.title = "🌸 Help Category: #{category}"
    embed.description = "**Prefix:** `#{PREFIX}` | **Slash:** `/`\n\n"

    if COMMAND_CATEGORIES[category]
      cmd_list = COMMAND_CATEGORIES[category].map do |cmd_sym|
        cmd = bot.commands[cmd_sym]
        desc = cmd ? (cmd.attributes[:description] || 'No description provided.') : 'No description provided.'
        "`#{cmd_sym}` - #{desc}"
      end
      embed.description += cmd_list.join("\n")
    else
      embed.description += "*Nothing here yet. Weird. That's on them, not me.*"
    end
    embed.description += "\n\n#{remark}"
  end
  embed.description += mom_remark(user_obj.id, 'general').to_s
  embed
end

def help_select_menu(user_id)
  Discordrb::Components::View.new do |v|
    v.row do |r|
      r.select_menu(custom_id: "help_menu_#{user_id}", placeholder: 'Pick a category, I dare you...', max_values: 1) do |s|
        s.option(label: 'Home', value: 'Home', emoji: '🏠', description: 'Back to the lobby~')
        
        emoji_map = { 'Economy' => '💰', 'Gacha' => '🌟', 'Arcade' => '🕹️', 'Fun' => '🎉', 'Utility' => '🔧', 'Admin' => '🛡️' }
        visible_categories = COMMAND_CATEGORIES.keys - ['Developer']
        
        visible_categories.each do |cat|
          s.option(label: cat, value: cat, emoji: emoji_map[cat] || '🌸')
        end
      end
    end
  end
end

def balance_select_menu(user_id, current_page, ach_page = 1, total_ach_pages = 1)
  Discordrb::Components::View.new do |v|
    v.row do |r|
      r.select_menu(custom_id: "bal_menu_#{user_id}", placeholder: "What do you wanna see?", max_values: 1) do |s|
        s.option(label: 'Balance & Stats', value: 'home', emoji: '💰', default: current_page == 'home')
        s.option(label: 'Inventory', value: 'inv', emoji: '🎒', default: current_page == 'inv')
        s.option(label: 'VTuber Totals', value: 'vtubers', emoji: '🌟', default: current_page == 'vtubers')
        s.option(label: 'Achievements', value: 'achievements', emoji: '🏆', default: current_page == 'achievements')
      end
    end

    if current_page == 'achievements' && total_ach_pages > 1
      v.row do |r|
        r.button(custom_id: "achpage_#{user_id}_#{ach_page - 1}", label: 'Previous', style: :primary, emoji: '◀️', disabled: ach_page <= 1)
        r.button(custom_id: "achpage_noop", label: "Page #{ach_page}/#{total_ach_pages}", style: :secondary, disabled: true)
        r.button(custom_id: "achpage_#{user_id}_#{ach_page + 1}", label: 'Next', style: :primary, emoji: '▶️', disabled: ach_page >= total_ach_pages)
      end
    end
  end
end

def leaderboard_select_menu(user_id, current_page)
  Discordrb::Components::View.new do |v|
    v.row do |r|
      r.select_menu(custom_id: "lb_menu_#{user_id}", placeholder: "Who's on top? Pick a board...", max_values: 1) do |s|
        s.option(label: 'Server Members (XP)', value: 'server_users', emoji: '👥', description: 'The grinders of this server', default: current_page == 'server_users')
        s.option(label: 'Global Communities', value: 'global_servers', emoji: '🌍', description: 'Most active arcades worldwide', default: current_page == 'global_servers')
        s.option(label: 'Global Richest (Coins)', value: 'global_coins', emoji: '💰', description: 'The whales. Respect.', default: current_page == 'global_coins')
      end
    end
  end
end

def generate_leaderboard_page(bot, server, action)
  embed = Discordrb::Webhooks::Embed.new(color: 0xFFD700)
  
  case action
  when 'server_users'
    embed.title = "👥 #{server.name} — Top Grinders"
    raw_top = DB.get_top_users(server.id, 50) 
    
    active_humans = []
    raw_top.each do |row|
      user_obj = bot.user(row['user_id'])
      if user_obj && !user_obj.bot_account? && server.member(user_obj.id)
        active_humans << row
        break if active_humans.size >= 10
      end
    end

    if active_humans.empty?
      embed.description = "*Nobody's even grinding yet?? Chat, do better.*"
    else
      desc = active_humans.each_with_index.map do |row, index|
        user_obj = bot.user(row['user_id'])
        name = user_obj.display_name
        premium_badge = is_premium?(bot, row['user_id']) ? " #{EMOJI_STRINGS['prisma']}" : ""
        medal = ["🥇", "🥈", "🥉"][index] || "🏅"
        "**#{index + 1}.** #{medal} **#{name}**#{premium_badge} — Level **#{row['level']}** *(#{row['xp']} XP)*"
      end.join("\n\n")
      embed.description = desc
    end

  when 'global_servers'
    embed.title = "🌍 Global Arcade Rankings"
    top_servers = DB.get_global_server_leaderboard(10) 

    if top_servers.empty?
      embed.description = "*No servers on the board yet. First come, first flex.*"
    else
      desc = top_servers.each_with_index.map do |row, index|
        # We pull the name directly from the database row!
        # If for some reason it's missing (from old data), fallback to "Unknown"
        name = row['server_name'] || "Unknown Arcade"
        
        sid = row['server_id'].to_i
        medal = ["🏆", "🥈", "🥉"][index] || "🏅"
        bolding = (server.id == sid) ? "**" : "" 
        
        "#{bolding}**#{index + 1}.** #{medal} **#{name}** — Level **#{row['level']}** *(#{row['xp']} XP)*#{bolding}"
      end.join("\n\n")
      embed.description = desc
    end

  when 'global_coins'
    embed.title = "💰 Global Rich List"
    raw_top = DB.get_top_coins(50) 
    
    active_humans = []
    raw_top.each do |row|
      user_obj = bot.user(row['user_id'])
      if user_obj && !user_obj.bot_account?
        active_humans << row
        break if active_humans.size >= 10
      end
    end

    if active_humans.empty?
      embed.description = "*Everyone's broke?? Down bad, chat.*"
    else
      desc = active_humans.each_with_index.map do |row, index|
        user_obj = bot.user(row['user_id'])
        name = user_obj ? user_obj.username : "User #{row['user_id']}"
        premium_badge = user_obj && is_premium?(bot, row['user_id']) ? " #{EMOJI_STRINGS['prisma']}" : ""
        medal = ["🥇", "🥈", "🥉"][index] || "🏅"

        "**#{index + 1}.** #{medal} **#{name}**#{premium_badge} — **#{row['coins']}** #{EMOJI_STRINGS['s_coin']}"
      end.join("\n\n")
      embed.description = desc
    end
  end
  embed
end

def carnival_back_view(owner_id)
  Discordrb::Components::View.new do |v|
    v.row { |r| r.button(custom_id: "carnival_hub_#{owner_id}", label: 'Back to Carnival Hub', style: :secondary, emoji: '🎪') }
  end
end