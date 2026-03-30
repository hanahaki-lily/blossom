# ==========================================
# COMMAND: dreset (Developer Only)
# DESCRIPTION: Resets all cooldowns for a user. Made for testing.
# CATEGORY: Developer
# ==========================================

def execute_dreset(event, target_user)
  unless DEV_IDS.include?(event.user.id)
    return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['x_']} Permission Denied" },
      { type: 14, spacing: 1 },
      { type: 10, content: "Only my creator can use this." }
    ]}])
  end

  target_user ||= event.user
  uid = target_user.id

  # Nuke all cooldown timestamps
  DatabaseCooldowns::VALID_COOLDOWN_TYPES.each do |type|
    DB.set_cooldown(uid, type, nil)
  end

  # Also reset daily claim so it can be re-tested
  DB.update_daily_claim(uid, 0, Time.at(0))

  # Reset pity counter too for gacha testing
  DB.reset_pity(uid)

  send_cv2(event, [{ type: 17, accent_color: 0x00FF00, components: [
    { type: 10, content: "## #{EMOJI_STRINGS['developer']} Cooldown Reset" },
    { type: 14, spacing: 1 },
    { type: 10, content: "All cooldowns wiped for **#{target_user.display_name}**.\nDaily, work, stream, post, collab, summon, spin, pity — all reset. Go wild, mom." }
  ]}])
end

# ------------------------------------------
# TRIGGERS: Prefix & Slash Support
# ------------------------------------------
$bot.command(:dreset,
  description: 'Reset all cooldowns for a user (Dev Only)',
  category: 'Developer'
) do |event|
  target = event.message.mentions.first || event.user
  execute_dreset(event, target)
  nil
end

$bot.application_command(:dreset) do |event|
  target_id = event.options['user']
  target = target_id ? event.bot.user(target_id.to_i) : event.user
  execute_dreset(event, target)
end
