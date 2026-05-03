# ==========================================
# COMMAND: vote (Top.gg)
# DESCRIPTION: Vote link, streak info, DM reminder toggle.
# CATEGORY: Utility
# ==========================================

def execute_vote_panel(event, action)
  uid = event.user.id
  action = action.to_s.downcase.strip
  action = 'info' if action.empty?

  if action == 'remind'
    on = DB.toggle_topgg_vote_reminder(uid)
    send_cv2(event, [{ type: 17, accent_color: NEON_COLORS.sample, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['neonsparkle']} top.gg vote reminders" },
      { type: 14, spacing: 1 },
      { type: 10, content: "DM reminders are now **#{on ? 'ON' : 'OFF'}**.#{on ? " I'll whisper when your cooldown's up so you can snag more #{EMOJI_STRINGS['prisma']}." : ' I will leave you alone about voting.'}#{family_remark(uid, 'general')}" }
    ]}])
    return
  end

  st = DB.topgg_vote_state(uid)
  url = TopggWebhook.vote_page_url
  cap = DatabaseVotes::TOPGG_STREAK_CAP
  gap_h = DatabaseVotes::TOPGG_STREAK_GAP_SECONDS / 3600
  base = DatabaseVotes::TOPGG_BASE_PRISMA
  webhook_ok = !ENV['TOPGG_WEBHOOK_SECRET'].to_s.strip.empty?

  next_line = if st[:next_vote_after]
                  ts = st[:next_vote_after].to_i
                  "You can vote again <t:#{ts}:R> (<t:#{ts}:f>)."
                else
                  'No vote on record yet — hit the link and your first drop lands after top.gg confirms the webhook.'
                end

  streak_line = "**Stored streak:** #{st[:vote_streak]} (cap **#{cap}** — rewards use **#{base} + streak**, max **#{base + cap}** Prisma per vote before weekend multipliers).\n**Streak rule:** vote again within **#{gap_h} hours** or it resets."

  rem_line = if st[:reminder_dm]
               "**Reminder DMs:** **on** — run `#{PREFIX}vote remind` to shut me up."
             else
               "**Reminder DMs:** **off** — run `#{PREFIX}vote remind` or `/vote` if you want pings."
             end

  lines = [
    "Support the Neon Arcade on **top.gg** and earn **#{EMOJI_STRINGS['prisma']}** automatically.",
    "**Vote:** #{url}",
    streak_line,
    next_line,
    rem_line,
    webhook_ok ? nil : "\n*Note: webhook secret not set on this process — set `TOPGG_WEBHOOK_SECRET` and expose `POST /webhooks/topgg` for automatic Prisma.*"
  ].compact

  send_cv2(event, [{ type: 17, accent_color: NEON_COLORS.sample, components: [
    { type: 10, content: "## #{EMOJI_STRINGS['prisma']} top.gg votes" },
    { type: 14, spacing: 1 },
    { type: 10, content: lines.join("\n\n") + family_remark(uid, 'general').to_s }
  ]}])
end

$bot.command(:vote, description: 'top.gg vote rewards & DM reminders', category: 'Utility') do |event, sub|
  if sub&.downcase == 'remind'
    execute_vote_panel(event, 'remind')
  else
    execute_vote_panel(event, 'info')
  end
  nil
end

$bot.application_command(:vote) do |event|
  act = event.options['action']
  act = 'info' if act.nil? || act.to_s.empty?
  execute_vote_panel(event, act)
end
