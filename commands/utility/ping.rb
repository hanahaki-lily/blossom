# ==========================================
# COMMAND: ping
# DESCRIPTION: Measures the round-trip latency between the bot and Discord.
# CATEGORY: Utility
# ==========================================

def execute_ping(event, timestamp)
  time_diff = Time.now - timestamp
  latency_ms = (time_diff * 1000).round

  components = [
    {
      type: 17,
      accent_color: NEON_COLORS.sample,
      components: [
        { type: 10, content: "## #{EMOJIS['play']} Pong!" },
        { type: 14, spacing: 1 },
        { type: 10, content: "My connection to Discord is **#{latency_ms}ms**.\nChat is moving fast!" }
      ]
    }
  ]

  send_cv2(event, components)
end

# ------------------------------------------
# TRIGGER: Prefix Command (b!ping)
# ------------------------------------------
$bot.command(:ping,
  description: 'Check bot latency',
  category: 'Utility'
) do |event|
  execute_ping(event, event.message.timestamp)
  nil
end

# ------------------------------------------
# TRIGGER: Slash Command (/ping)
# ------------------------------------------
$bot.application_command(:ping) do |event|
  execute_ping(event, (event.interaction.creation_time rescue Time.now))
end
