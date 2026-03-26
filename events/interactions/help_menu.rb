# ==========================================
# EVENT: Help Menu Hub
# DESCRIPTION: Listens for category selections on the /help dropdown.
# ==========================================

CV2_FLAG = 1 << 15 unless defined?(CV2_FLAG)

$bot.select_menu(custom_id: /^help_menu_/) do |event|
  owner_id = event.custom_id.split('_').last

  if event.user.id.to_s != owner_id
    event.respond(content: "🌸 *This isn't your menu! Run your own `#{PREFIX}help` command to explore.*", ephemeral: true)
    next
  end

  selected_category = event.values.first
  components = help_cv2_components(event.bot, owner_id, selected_category)

  event.update_message(content: '', flags: CV2_FLAG, components: components)
end
