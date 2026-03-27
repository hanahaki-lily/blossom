# ==========================================
# COMMAND: kettle
# DESCRIPTION: Sends a sparkly shout-out ping to a specific user.
# CATEGORY: Fun / Inside Jokes
# ==========================================

# ------------------------------------------
# LOGIC: Kettle Shout-out Execution
# ------------------------------------------
def execute_kettle(event)
  # 1. Initialization: Define the hardcoded target and the sparkle wrapper
  # User ID: 266358927401287680
  shoutout_msg = "#{EMOJI_STRINGS['sparkle']} <@266358927401287680> #{EMOJI_STRINGS['sparkle']}"

  # 2. Messaging: Respond based on the event trigger type
  if event.is_a?(Discordrb::Events::ApplicationCommandEvent)
    # Slash Command Response
    event.respond(content: shoutout_msg)
  else
    # Prefix Command Response
    event.channel.send_message(shoutout_msg, false, nil, nil, nil, event.message)
  end
end

# ------------------------------------------
# TRIGGER: Prefix Command (b!kettle)
# ------------------------------------------
$bot.command(:kettle, aliases: [:ket],
  description: 'Pings a specific user with a yay emoji', 
  category: 'Fun'
) do |event|
  execute_kettle(event)
  nil # Suppress default return
end

# ------------------------------------------
# TRIGGER: Slash Command (/kettle)
# ------------------------------------------
$bot.application_command(:kettle) do |event|
  execute_kettle(event)
end