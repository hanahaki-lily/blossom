# ==========================================
# COMMAND: spin (Daily Wheel Spin)
# DESCRIPTION: Free daily spin for random prizes. Premium: 1 free reroll.
# CATEGORY: Arcade
# ==========================================

SPIN_COOLDOWN = 24 * 60 * 60

WHEEL_PRIZES = [
  { type: :coins, amount: 50,    weight: 20, label: "50 #{EMOJI_STRINGS['s_coin']}",              emoji: EMOJI_STRINGS['common'] },
  { type: :coins, amount: 100,   weight: 18, label: "100 #{EMOJI_STRINGS['s_coin']}",             emoji: EMOJI_STRINGS['common'] },
  { type: :coins, amount: 250,   weight: 15, label: "250 #{EMOJI_STRINGS['s_coin']}",             emoji: EMOJI_STRINGS['common'] },
  { type: :coins, amount: 500,   weight: 12, label: "500 #{EMOJI_STRINGS['s_coin']}",             emoji: EMOJI_STRINGS['rare'] },
  { type: :coins, amount: 1000,  weight: 10, label: "1,000 #{EMOJI_STRINGS['s_coin']}",           emoji: EMOJI_STRINGS['rare'] },
  { type: :coins, amount: 2500,  weight: 7,  label: "2,500 #{EMOJI_STRINGS['s_coin']}",           emoji: EMOJI_STRINGS['legendary'] },
  { type: :coins, amount: 5000,  weight: 5,  label: "5,000 #{EMOJI_STRINGS['s_coin']}",           emoji: EMOJI_STRINGS['neonsparkle'] },
  { type: :prisma, amount: 5,    weight: 5,  label: "5 #{EMOJI_STRINGS['prisma']}",               emoji: EMOJI_STRINGS['prisma'] },
  { type: :prisma, amount: 10,   weight: 3,  label: "10 #{EMOJI_STRINGS['prisma']}",              emoji: EMOJI_STRINGS['prisma'] },
  { type: :legendary, amount: 1, weight: 3,  label: "Random Legendary!",                          emoji: EMOJI_STRINGS['legendary'] },
  { type: :goddess, amount: 1,   weight: 2,  label: "Random Goddess!!",                           emoji: EMOJI_STRINGS['goddess'] }
].freeze

def spin_the_wheel
  total = WHEEL_PRIZES.sum { |p| p[:weight] }
  roll = rand(total)
  cumulative = 0
  WHEEL_PRIZES.each do |prize|
    cumulative += prize[:weight]
    return prize if roll < cumulative
  end
  WHEEL_PRIZES.first
end

def award_spin_prize(bot, uid, prize)
  extra_text = ""
  case prize[:type]
  when :coins
    final = award_coins(bot, uid, prize[:amount])
    extra_text = "**#{final}** #{EMOJI_STRINGS['s_coin']} added to your wallet!"
  when :prisma
    DB.add_prisma(uid, prize[:amount])
    extra_text = "**#{prize[:amount]}** #{EMOJI_STRINGS['prisma']} added to your Prisma balance!"
  when :legendary
    banner = get_current_banner
    char = banner[:characters][:legendary].sample
    DB.add_character(uid, char[:name], 'legendary', 1)
    extra_text = "You got #{EMOJI_STRINGS['legendary']} **#{char[:name]}** (Legendary)! Added to your collection!"
  when :goddess
    banner = get_current_banner
    char = banner[:characters][:goddess].sample
    DB.add_character(uid, char[:name], 'goddess', 1)
    extra_text = "YOU GOT #{EMOJI_STRINGS['goddess']} **#{char[:name]}** (GODDESS)!! ACTUALLY INSANE!!"
  end
  extra_text
end

def spin_accent_color(prize)
  case prize[:type]
  when :goddess then 0xFF00FF
  when :legendary then 0xFFAA00
  when :prisma then 0xAA00FF
  else NEON_COLORS.sample
  end
end

# ------------------------------------------
# LOGIC: Spin Execution
# ------------------------------------------
def execute_spin(event)
  uid = event.user.id
  now = Time.now
  is_sub = is_premium?(event.bot, uid)
  last_used = DB.get_cooldown(uid, 'spin')

  # Cooldown check (24h)
  if last_used && (now - last_used) < SPIN_COOLDOWN
    ready_time = (last_used + SPIN_COOLDOWN).to_i
    return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['x_']} Daily Spin" },
      { type: 14, spacing: 1 },
      { type: 10, content: "You already spun today, chat! Come back <t:#{ready_time}:R>." }
    ]}])
  end

  # Spin!
  DB.set_cooldown(uid, 'spin', now)
  prize = spin_the_wheel
  result_text = award_spin_prize(event.bot, uid, prize)

  # Build the visual wheel display
  wheel_display = WHEEL_PRIZES.map { |p| p == prize ? "**▶ #{p[:emoji]} #{p[:label]} ◀**" : "-# #{p[:emoji]} #{p[:label]}" }.join("\n")

  inner = [
    { type: 10, content: "## 🎡 Daily Wheel Spin" },
    { type: 14, spacing: 1 },
    { type: 10, content: wheel_display },
    { type: 14, spacing: 1 },
    { type: 10, content: "#{result_text}\nBalance: **#{DB.get_coins(uid)}** #{EMOJI_STRINGS['s_coin']}#{mom_remark(uid, 'arcade')}" }
  ]

  # Premium reroll button
  if is_sub
    inner << { type: 1, components: [
      { type: 2, style: 1, label: "Reroll (Premium)", custom_id: "spin_reroll_#{uid}", emoji: { name: '🔄' } }
    ]}
  end

  send_cv2(event, [{ type: 17, accent_color: spin_accent_color(prize), components: inner }])
end

# ------------------------------------------
# TRIGGERS: Prefix & Slash Support
# ------------------------------------------
$bot.command(:spin, aliases: [:wheel],
  description: 'Spin the daily prize wheel!',
  category: 'Arcade'
) do |event|
  execute_spin(event)
  nil
end

$bot.application_command(:spin) do |event|
  execute_spin(event)
end
