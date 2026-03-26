# ==========================================
# COMMAND: help
# DESCRIPTION: The primary navigation hub for all bot commands.
# CATEGORY: Utility
# ==========================================

def execute_help(event)
  components = help_cv2_components(event.bot, event.user.id, 'Home')
  send_cv2(event, components)
end

# ------------------------------------------
# TRIGGERS
# ------------------------------------------
$bot.command(:help,
  description: 'Shows the interactive help menu',
  category: 'Utility'
) do |event|
  execute_help(event)
  nil
end

$bot.application_command(:help) do |event|
  execute_help(event)
end
