# ==========================================
# EVENT: Spin Reroll Handler (Premium Perk)
# DESCRIPTION: Premium users get 1 free reroll on the daily wheel.
# The reroll replaces the original prize — could be better or worse!
# ==========================================

$bot.button(custom_id: /^spin_reroll_/) do |event|
  uid = event.custom_id.split('_').last.to_i

  if event.user.id != uid
    next event.respond(content: "#{EMOJI_STRINGS['x_']} Not your wheel, chat.", ephemeral: true)
  end

  unless is_premium?(event.bot, uid)
    next event.respond(content: "#{EMOJI_STRINGS['prisma']} This is a Premium perk!", ephemeral: true)
  end

  # Spin a new prize
  prize = spin_the_wheel
  result_text = award_spin_prize(event.bot, uid, prize)

  # Build the updated display
  wheel_display = WHEEL_PRIZES.map { |p| p == prize ? "**▶ #{p[:emoji]} #{p[:label]} ◀**" : "-# #{p[:emoji]} #{p[:label]}" }.join("\n")

  inner = [
    { type: 10, content: "## 🎡 Daily Wheel Spin — **REROLLED!**" },
    { type: 14, spacing: 1 },
    { type: 10, content: wheel_display },
    { type: 14, spacing: 1 },
    { type: 10, content: "🔄 *Premium reroll used!*\n#{result_text}\nBalance: **#{DB.get_coins(uid)}** #{EMOJI_STRINGS['s_coin']}#{mom_remark(uid, 'arcade')}" }
  ]

  event.update_message(
    content: '', flags: CV2_FLAG,
    components: [{ type: 17, accent_color: spin_accent_color(prize), components: inner }]
  )
end
