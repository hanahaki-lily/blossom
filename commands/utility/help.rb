# ==========================================
# COMMAND: help
# DESCRIPTION: The primary navigation hub for all bot commands.
# CATEGORY: Utility
# ==========================================

def execute_help(event, category = nil)
  # Resolve category from user input (case-insensitive match)
  if category && !category.strip.empty?
    match = COMMAND_CATEGORIES.keys.find { |k| k.downcase == category.strip.downcase }
    target = match || 'Home'
  else
    target = 'Home'
  end

  components = help_cv2_components(event.bot, event.user.id, target, 1)
  send_cv2(event, components)
end

# ------------------------------------------
# TRIGGERS
# ------------------------------------------
$bot.command(:help, aliases: [:cmds, :commands],
  description: 'Shows the interactive help menu',
  category: 'Utility'
) do |event, *args|
  execute_help(event, args.join(' '))
  nil
end

$bot.application_command(:help) do |event|
  execute_help(event)
end
