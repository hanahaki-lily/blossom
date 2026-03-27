# ==========================================
# COMMAND: interactions
# DESCRIPTION: Displays the user's total sent and received hugs and slaps.
# CATEGORY: Social / Fun
# ==========================================

# ------------------------------------------
# LOGIC: Interaction Stats Execution
# ------------------------------------------
def execute_interactions(event)
  # 1. Data Retrieval: Fetch the full interaction hash for the user
  # This returns a structure like: { 'hug' => { 'sent' => 0, 'received' => 0 }, ... }
  data = DB.get_interactions(event.user.id)
  
  # 2. UI: Construct the CV2 Container
  components = [
    {
      type: 17,
      accent_color: NEON_COLORS.sample,
      components: [
        { type: 10, content: "## 📊 #{event.user.display_name}'s Interaction Stats" },
        { type: 14, spacing: 1 },
        { type: 10, content: "Your social history in the Neon Arcade. Are you a lover, a fighter, or a head-patter? Let's find out." },
        { type: 14, spacing: 1 },
        { type: 10, content: "**💕 Hugs**\nSent: **#{data['hug']['sent']}** | Received: **#{data['hug']['received']}**" },
        { type: 14, spacing: 1 },
        { type: 10, content: "**🔨 Slaps**\nSent: **#{data['slap']['sent']}** | Received: **#{data['slap']['received']}**" },
        { type: 14, spacing: 1 },
        { type: 10, content: "**#{EMOJI_STRINGS['hearts']} Pats**\nSent: **#{data['pat']['sent']}** | Received: **#{data['pat']['received']}**#{mom_remark(event.user.id, 'general')}" }
      ]
    }
  ]
  send_cv2(event, components)
end

# ------------------------------------------
# TRIGGER: Prefix Command (b!interactions)
# ------------------------------------------
$bot.command(:interactions, aliases: [:int, :stats],
  description: 'Show your hug/slap stats', 
  category: 'Fun'
) do |event|
  execute_interactions(event)
  nil # Suppress default return
end

# ------------------------------------------
# TRIGGER: Slash Command (/interactions)
# ------------------------------------------
$bot.application_command(:interactions) do |event|
  execute_interactions(event)
end