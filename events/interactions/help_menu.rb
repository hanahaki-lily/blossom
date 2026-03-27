# ==========================================
# EVENT: Help Menu Hub
# DESCRIPTION: Listens for category selections on the /help dropdown
# and page button clicks for pagination.
# ==========================================

CV2_FLAG = 1 << 15 unless defined?(CV2_FLAG)

# Dropdown category selection
$bot.select_menu(custom_id: /^help_menu_/) do |event|
  owner_id = event.custom_id.split('_').last

  if event.user.id.to_s != owner_id
    event.respond(content: "🌸 *This isn't your menu! Run your own `#{PREFIX}help` command to explore.*", ephemeral: true)
    next
  end

  selected_category = event.values.first
  components = help_cv2_components(event.bot, owner_id, selected_category, 1)

  event.update_message(content: '', flags: CV2_FLAG, components: components)
end

# Pagination button clicks
$bot.button(custom_id: /^helppg_/) do |event|
  next if event.custom_id == 'helppg_noop'

  parts = event.custom_id.split('_')
  owner_id = parts[1]
  category = parts[2]
  target_page = parts[3].to_i

  if event.user.id.to_s != owner_id
    event.respond(content: "🌸 *Not your help menu, chat! Use `#{PREFIX}help` to open yours.*", ephemeral: true)
    next
  end

  components = help_cv2_components(event.bot, owner_id, category, target_page)
  event.update_message(content: '', flags: CV2_FLAG, components: components)
end
