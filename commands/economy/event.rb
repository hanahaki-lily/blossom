# ==========================================
# COMMAND: event (Seasonal Hub)
# DESCRIPTION: Opens an interactive menu to access limited-time minigames and events.
# CATEGORY: Economy / Seasonal
# ==========================================

# ------------------------------------------
# LOGIC: Event Hub Execution
# ------------------------------------------
def execute_event_hub(event)
  # 1. UI: Construct the primary Hub Embed
  embed = Discordrb::Webhooks::Embed.new(
    title: "🗓️ Blossom Event Hub",
    description: "Yo chat, you found the secret menu! Well, not secret, but definitely exclusive. 🌸\n\n" \
                 "This is where the LIMITED TIME stuff lives — seasonal minigames, event currency, and VTubers you literally CANNOT get anywhere else. Pick an event from the dropdown and let's see what's poppin'.#{mom_remark(event.user.id, 'general')}",
    color: 0xFF69B4 # Classic Blossom Pink
  )
  
  # 2. Components: Create the Select Menu for seasonal navigation
  view = Discordrb::Components::View.new do |v|
    v.row do |r|
      # We include the User ID in the custom_id to ensure only the person 
      # who opened the hub can interact with the menu.
      r.select_menu(
        custom_id: "event_hub_#{event.user.id}", 
        placeholder: "Pick an event, I dare you...",
        max_values: 1
      ) do |s|
        # 3. Dynamic Options: Swap these labels and values as seasons change!
        s.option(
          label: "Spring Carnival", 
          value: "spring_carnival", 
          emoji: "🎪", 
          description: "April Exclusive Event!"
        )
      end
    end
  end

  # 4. Messaging: Handle execution context (Slash vs. Prefix)
  if event.is_a?(Discordrb::Events::ApplicationCommandEvent)
    event.respond(embeds: [embed], components: view)
  else
    event.channel.send_message(nil, false, embed, nil, nil, event.message, view)
  end
end

# ------------------------------------------
# TRIGGER: Prefix Command (b!event)
# ------------------------------------------
$bot.command(:event, aliases: [:ev],
  description: 'Open the Limited Time Event Hub!', 
  category: 'Economy'
) do |event|
  execute_event_hub(event)
  nil # Suppress default return
end

# ------------------------------------------
# TRIGGER: Slash Command (/event)
# ------------------------------------------
$bot.application_command(:event) do |event|
  execute_event_hub(event)
end