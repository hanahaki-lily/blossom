# ==========================================
# COMMAND: eventvip
# DESCRIPTION: Daily bonus event currency for subscribers during seasonal events.
# CATEGORY: Economy
# ==========================================

def execute_eventvip(event)
  uid = event.user.id
  unless is_premium?(event.bot, uid)
    return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['prisma']} Premium Only" },
      { type: 14, spacing: 1 },
      { type: 10, content: "The **Event VIP Lane** is subscriber-only. `/premium` has the pitch~" }
    ]}])
  end

  unless event_active?
    return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['x_']} No Event" },
      { type: 14, spacing: 1 },
      { type: 10, content: "No seasonal event is running this month. Check back when the calendar says party time~" }
    ]}])
  end

  ev = get_active_event
  today = Date.today
  if DB.event_vip_claimed_today?(uid, today)
    return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['x_']} Cooldown" },
      { type: 14, spacing: 1 },
      { type: 10, content: "You already grabbed your **Event VIP** bonus today. Tomorrow's another round~" }
    ]}])
  end

  n = rand(EVENT_VIP_TICKET_MIN..EVENT_VIP_TICKET_MAX)
  DB.add_tickets(uid, n)
  DB.mark_event_vip_claimed(uid, today)

  send_cv2(event, [{ type: 17, accent_color: NEON_COLORS.sample, components: [
    { type: 10, content: "## #{EMOJI_STRINGS['prisma']} #{ev[:name]} — VIP Lane" },
    { type: 14, spacing: 1 },
    { type: 10, content: "Daily subscriber drip unlocked~\n\n**+#{n}** #{ev[:emoji]} *(#{ev[:currency]})*\n\n**New balance:** #{DB.get_tickets(uid)} #{ev[:emoji]}#{mom_remark(uid, 'economy')}" }
  ]}])
end

$bot.command(:eventvip, aliases: %i[eventlane vipbonus],
             description: 'Daily bonus event currency (subscribers, during events)',
             category: 'Economy') do |event|
  execute_eventvip(event)
  nil
end

$bot.application_command(:eventvip) do |event|
  execute_eventvip(event)
end
