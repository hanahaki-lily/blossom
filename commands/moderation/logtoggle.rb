# ==========================================
# COMMAND: logtoggle
# DESCRIPTION: Enable or disable specific logging categories for the server.
# CATEGORY: Moderation
# ==========================================

# ------------------------------------------
# LOGIC: Toggle Execution
# ------------------------------------------
def execute_logtoggle(event, type)
  # 1. Security: Ensure the user has "Manage Server" permissions
  unless event.user.permission?(:manage_server) || DEV_IDS.include?(event.user.id)
    return event.respond(content: "#{EMOJI_STRINGS['x_']} *You need the Manage Server permission to do this!*", ephemeral: true)
  end

  # 2. Validation: Map user-friendly names to actual database columns
  valid_types = {
    'deletes' => 'log_deletes',
    'edits'   => 'log_edits',
    'mod'     => 'log_mod',
    'dms'     => 'dm_mods',
    'joins'   => 'log_joins',
    'leaves'  => 'log_leaves'
  }

  type = type&.downcase

  unless valid_types.key?(type)
    return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['confused']} Toggle What?" },
      { type: 14, spacing: 1 },
      { type: 10, content: "Tell me what to toggle, chat. Options:\n" \
                   "- `deletes` — Message deletions\n" \
                   "- `edits` — Message edits\n" \
                   "- `mod` — Mod actions (kick/ban/timeout)\n" \
                   "- `dms` — DM mods on actions\n" \
                   "- `joins` — Member join logs\n" \
                   "- `leaves` — Member leave logs\n\n" \
                   "`#{PREFIX}logtoggle <type>`" }
    ]}])
  end

  # 3. Database: Execute the toggle logic
  db_column = valid_types[type]
  is_now_on = DB.toggle_log_setting(event.server.id, db_column)

  # 4. UI: Determine the visual status indicator
  status = is_now_on ? "**ON** :green_circle:" : "**OFF** :red_circle:"

  # 5. Feedback: Confirm the update to the administrator
  flavor = is_now_on ? "I'm watching **#{type}** like a hawk now. Nothing gets past me." : "Fine, I'll stop snooping on **#{type}**. Your loss if something happens."
  send_cv2(event, [{ type: 17, accent_color: NEON_COLORS.sample, components: [
    { type: 10, content: "## #{EMOJI_STRINGS['info']} Logging Updated" },
    { type: 14, spacing: 1 },
    { type: 10, content: "**#{type.capitalize}** logging is now #{status}.\n\n*#{flavor}*#{mom_remark(event.user.id, 'mod')}" }
  ]}])
end

# ------------------------------------------
# TRIGGER: Prefix Command (b!logtoggle)
# ------------------------------------------
$bot.command(:logtoggle, aliases: [:lt],
  description: 'Toggle logging for deletes, edits, mod, dms, joins, or leaves',
  category: 'Moderation'
) do |event, type|
  execute_logtoggle(event, type)
  nil # Suppress default return
end

# ------------------------------------------
# TRIGGER: Slash Command (/logtoggle)
# ------------------------------------------
$bot.application_command(:logtoggle) do |event|
  execute_logtoggle(event, event.options['type'])
end
