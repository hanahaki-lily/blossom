# ==========================================
# COMMAND: dleave (Developer Only)
# DESCRIPTION: Makes the bot leave a guild by snowflake ID.
# CATEGORY: Developer
# ==========================================

DLEAVE_USAGE = "**Usage:** `#{PREFIX}dleave <server_id>`\nExample: `#{PREFIX}dleave 991234567890123456`"

def execute_dleave(event, raw_server_id)
  unless DEV_IDS.include?(event.user.id)
    return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['x_']} Permission Denied" },
      { type: 14, spacing: 1 },
      { type: 10, content: "Only my creator can use this." }
    ]}])
  end

  sid_str = raw_server_id.to_s.strip
  if sid_str.empty?
    return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['confused']} Which Server?" },
      { type: 14, spacing: 1 },
      { type: 10, content: "Drop a guild snowflake, mom.\n\n#{DLEAVE_USAGE}" }
    ]}])
  end

  unless sid_str.match?(/\A\d{17,20}\z/)
    return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['confused']} Bad ID" },
      { type: 14, spacing: 1 },
      { type: 10, content: "That doesn't look like a Discord server snowflake (17–20 digits).\n\n#{DLEAVE_USAGE}" }
    ]}])
  end

  sid = sid_str.to_i
  server = event.bot.server(sid)
  unless server
    return send_cv2(event, [{ type: 17, accent_color: 0xFFA500, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['confused']} Not There" },
      { type: 14, spacing: 1 },
      { type: 10, content: "I'm not in a server with ID `#{sid}`. Double-check the snowflake or I already dipped." }
    ]}])
  end

  label = server.name.to_s.empty? ? "Unknown" : server.name

  begin
    server.leave
  rescue StandardError => e
    return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['error']} Leave Failed" },
      { type: 14, spacing: 1 },
      { type: 10, content: "Discord said no — `#{e.class}: #{e.message}`" }
    ]}])
  end

  send_cv2(event, [{ type: 17, accent_color: 0x00FF00, components: [
    { type: 10, content: "## #{EMOJI_STRINGS['checkmark']} Left Server" },
    { type: 14, spacing: 1 },
    { type: 10, content: "Peace out from **#{label}** (`#{sid}`). Arcade's closed there." }
  ]}])
end

$bot.command(:dleave,
  description: 'Leave a guild by ID (Dev Only)',
  category: 'Developer'
) do |event, server_id|
  execute_dleave(event, server_id)
  nil
end
