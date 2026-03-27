# ==========================================
# COMMAND: achievements (Admin Only)
# DESCRIPTION: Toggles achievement notification messages for the server.
# CATEGORY: Admin
# ==========================================

# ------------------------------------------
# LOGIC: Achievement Toggle Execution
# ------------------------------------------
def execute_achievements_toggle(event)
  # 1. Security: Permission Check (Admins or Developer Only)
  unless DEV_IDS.include?(event.user.id) || event.user.permission?(:administrator, event.channel)
    return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['x_']} Access Denied" },
      { type: 14, spacing: 1 },
      { type: 10, content: "Nah, this is admin territory. You don't have the perms for this one, chat." }
    ]}])
  end

  # 2. Toggle: Flip the setting and get the new state
  now_enabled = DB.toggle_achievements(event.server.id)

  # 3. Messaging: Confirm the new state
  if now_enabled
    send_cv2(event, [{ type: 17, accent_color: 0x00FF00, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['achievement']} Achievement Notifications Enabled" },
      { type: 14, spacing: 1 },
      { type: 10, content: "Achievement unlock messages will now show up in chat. Time to flex on everyone.#{mom_remark(event.user.id, 'admin')}" }
    ]}])
  else
    send_cv2(event, [{ type: 17, accent_color: NEON_COLORS.sample, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['mute']} Achievement Notifications Disabled" },
      { type: 14, spacing: 1 },
      { type: 10, content: "Achievement unlocks will be silent in this server. Players still earn them, they just won't see the pop-up here.#{mom_remark(event.user.id, 'admin')}" }
    ]}])
  end
end

# ------------------------------------------
# TRIGGER: Prefix Command (b!achievements)
# ------------------------------------------
$bot.command(:achievements, aliases: [:ach],
  description: 'Toggle achievement notifications for this server (Admin Only)',
  category: 'Admin'
) do |event|
  execute_achievements_toggle(event)
  nil
end

# ------------------------------------------
# TRIGGER: Slash Command (/achievements)
# ------------------------------------------
$bot.application_command(:achievements) do |event|
  execute_achievements_toggle(event)
end
