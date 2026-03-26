# ==========================================
# HELPER: Interactive UI Builders (Hubs & Menus)
# DESCRIPTION: Generates the embeds and component views 
# for Blossom's general navigation tools.
# ==========================================

# Builds the raw CV2 select menu action row for the help menu dropdown.
def help_select_menu_raw(user_id)
  emoji_map = { 'Economy' => '💰', 'Gacha' => '🌟', 'Arcade' => '🕹️', 'Fun' => '🎉', 'Utility' => '🔧', 'Admin' => '🛡️' }
  visible_categories = COMMAND_CATEGORIES.keys - ['Developer']

  options = [{ label: 'Home', value: 'Home', emoji: { name: '🏠' }, description: 'Back to the lobby~' }]
  visible_categories.each do |cat|
    options << { label: cat, value: cat, emoji: { name: emoji_map[cat] || '🌸' } }
  end

  {
    type: 1, # Action Row
    components: [{
      type: 3, # String Select Menu
      custom_id: "help_menu_#{user_id}",
      placeholder: 'Pick a category, I dare you...',
      max_values: 1,
      options: options
    }]
  }
end

# Generates the full CV2 component array for a help page (container + select menu).
def help_cv2_components(bot, user_id, category)
  if category == 'Home'
    text_content = "Okay look, since you clearly need me to spell it out... welcome to the Neon Arcade. 🌸\n\n" \
                   "**Prefix:** `#{PREFIX}`\n" \
                   "*Everything works as Slash (`/`) or Prefix — I'm versatile like that.*\n\n" \
                   "Pick a category from the dropdown. Try not to get lost."
    inner = [
      { type: 10, content: "## #{EMOJI_STRINGS['info']} Blossom Help Menu" },
      { type: 14, spacing: 1 },
      { type: 10, content: text_content }
    ]
  else
    if COMMAND_CATEGORIES[category]
      cmd_list = COMMAND_CATEGORIES[category].map do |cmd_sym|
        cmd = bot.commands[cmd_sym]
        desc = cmd ? (cmd.attributes[:description] || 'No description provided.') : 'No description provided.'
        "`#{cmd_sym}` — #{desc}"
      end
      text_content = "**Prefix:** `#{PREFIX}` | **Slash:** `/`\n\n" + cmd_list.join("\n")
    else
      text_content = "*Nothing here yet. Weird. That's on them, not me.*"
    end

    inner = [
      { type: 10, content: "## 🌸 Help: #{category}" },
      { type: 14, spacing: 1 },
      { type: 10, content: text_content }
    ]
  end

  [
    { type: 17, accent_color: NEON_COLORS.sample, components: inner },
    help_select_menu_raw(user_id)
  ]
end

def generate_category_embed(bot, user_obj, category)
  embed = Discordrb::Webhooks::Embed.new
  embed.color = NEON_COLORS.sample
  embed.timestamp = Time.now
  embed.footer = Discordrb::Webhooks::EmbedFooter.new(text: "Requested by #{user_obj.display_name}", icon_url: user_obj.avatar_url)

  if category == 'Home'
    embed.title = "#{EMOJI_STRINGS['info']} Blossom Help Menu"
    embed.description = "Okay look, since you clearly need me to spell it out... welcome to the Neon Arcade. 🌸\n\n" \
                        "**Prefix:** `#{PREFIX}`\n" \
                        "*Everything works as Slash (`/`) or Prefix — I'm versatile like that.* \n\n" \
                        "Pick a category from the dropdown. Try not to get lost."
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
  end
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
        medal = ["🥇", "🥈", "🥉"][index] || "🏅"
        "**#{index + 1}.** #{medal} **#{name}** — Level **#{row['level']}** *(#{row['xp']} XP)*"
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
        medal = ["🥇", "🥈", "🥉"][index] || "🏅"
        
        "**#{index + 1}.** #{medal} **#{name}** — **#{row['coins']}** #{EMOJI_STRINGS['s_coin']}" 
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