# ==========================================
# COMMAND: vipcrate
# DESCRIPTION: Monthly subscriber reward crate (coins + Prisma).
# CATEGORY: Economy
# ==========================================

def execute_vipcrate(event)
  uid = event.user.id
  unless is_premium?(event.bot, uid)
    return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['prisma']} Premium Only" },
      { type: 14, spacing: 1 },
      { type: 10, content: "The **VIP Crate** is for **Blossom Premium** subs only. `/premium` has the link~" }
    ]}])
  end

  ym = DB.premium_month_ym
  if DB.premium_monthly_chest_claimed?(uid, ym)
    return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['x_']} Already Claimed" },
      { type: 14, spacing: 1 },
      { type: 10, content: "You already cracked your crate for **#{ym}**. Next one drops when the calendar rolls over~" }
    ]}])
  end

  coins_raw = SUBSCRIBER_MONTHLY_CHEST_COINS_RAW
  payout = calculate_coin_payout(event.bot, uid, coins_raw)
  prisma_amt = SUBSCRIBER_MONTHLY_CHEST_PRISMA

  DB.add_coins(uid, payout)
  DB.add_prisma(uid, prisma_amt)
  grant_crew_xp_for_coin_payout(uid, payout, event.bot)
  DB.mark_monthly_chest_claimed(uid, ym)

  send_cv2(event, [{ type: 17, accent_color: 0x00FF00, components: [
    { type: 10, content: "## #{EMOJI_STRINGS['crown']} VIP Crate — #{ym}" },
    { type: 14, spacing: 1 },
    { type: 10, content: "Here's your monthly sub loot, chat!\n\n**+#{payout}** #{EMOJI_STRINGS['s_coin']}\n**+#{prisma_amt}** #{EMOJI_STRINGS['prisma']}\n\n*(Loot uses your normal subscriber + crew multipliers on coins.)*#{mom_remark(uid, 'economy')}" }
  ]}])
end

$bot.command(:vipcrate, aliases: %i[subcrate monthlycrate],
             description: 'Claim your monthly subscriber reward crate',
             category: 'Economy') do |event|
  execute_vipcrate(event)
  nil
end

$bot.application_command(:vipcrate) do |event|
  execute_vipcrate(event)
end
