# ==========================================
# COMMAND: welcomer (Admin Only)
# DESCRIPTION: Enable or disable the welcome message system for the server.
# CATEGORY: Admin
# ==========================================

# ------------------------------------------
# LOGIC: Welcomer Configuration Execution
# ------------------------------------------
def execute_welcomer(event, action, channel_obj = nil)
  # 1. Security: Permission Check (Admins or Developer Only)
  unless DEV_IDS.include?(event.user.id) || event.user.permission?(:administrator, event.channel)
    return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['x_']} Access Denied" },
      { type: 14, spacing: 1 },
      { type: 10, content: "This is an admin-only feature, bestie. Come back with the right permissions." }
    ]}])
  end

  action = action&.downcase

  case action
  when 'enable'
    # Need a channel to enable
    unless channel_obj
      return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
        { type: 10, content: "## #{EMOJI_STRINGS['confused']} Which Channel?" },
        { type: 14, spacing: 1 },
        { type: 10, content: "You gotta tell me WHERE to welcome people, chat.\n\n" \
                     "**Slash:** `/welcomer action:Enable channel:#general`\n" \
                     "**Prefix:** `#{PREFIX}welcomer enable #channel`" }
      ]}])
    end

    DB.set_welcome_config(event.server.id, channel_obj.id, true)
    send_cv2(event, [{ type: 17, accent_color: 0x00FF00, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['checkmark']} Welcomer Enabled!" },
      { type: 14, spacing: 1 },
      { type: 10, content: "New members will get a welcome message in #{channel_obj.mention}.\nI'll make sure they feel the Neon Arcade energy from the moment they walk in.#{mom_remark(event.user.id, 'admin')}" }
    ]}])

  when 'disable'
    config = DB.get_welcome_config(event.server.id)
    DB.set_welcome_config(event.server.id, config[:channel], false)
    send_cv2(event, [{ type: 17, accent_color: NEON_COLORS.sample, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['mute']} Welcomer Disabled" },
      { type: 14, spacing: 1 },
      { type: 10, content: "Welcome messages are OFF. New members will enter in silence. Kinda ominous if you ask me.#{mom_remark(event.user.id, 'admin')}" }
    ]}])

  else
    send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['confused']} Welcomer Setup" },
      { type: 14, spacing: 1 },
      { type: 10, content: "Tell me what to do, chat:\n\n" \
                   "**Enable:** `#{PREFIX}welcomer enable #channel`\n" \
                   "**Disable:** `#{PREFIX}welcomer disable`" }
    ]}])
  end
end

# ------------------------------------------
# TRIGGER: Prefix Command (b!welcomer)
# ------------------------------------------
$bot.command(:welcomer, aliases: [:welcome],
  description: 'Enable or disable the server welcome message (Admin Only)',
  category: 'Admin'
) do |event, action, channel_mention|
  chan = nil
  if channel_mention =~ /<#(\d+)>/
    chan = event.bot.channel($1.to_i, event.server)
  end
  execute_welcomer(event, action, chan)
  nil
end

# ------------------------------------------
# TRIGGER: Slash Command (/welcomer)
# ------------------------------------------
$bot.application_command(:welcomer) do |event|
  chan_id = event.options['channel']
  chan = chan_id ? event.bot.channel(chan_id.to_i, event.server) : nil
  execute_welcomer(event, event.options['action'], chan)
end
