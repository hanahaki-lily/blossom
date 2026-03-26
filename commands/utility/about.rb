# ==========================================
# COMMAND: about
# DESCRIPTION: Displays the bot's purpose, features, and developer credits.
# CATEGORY: Utility
# ==========================================

def execute_about(event)
  components = [
    {
      type: 17,
      accent_color: 0xFF69B4,
      components: [
        { type: 10, content: "## 💖 About Blossom" },
        { type: 14, spacing: 1 },
        {
          type: 10,
          content: "Hey Chat! I'm **Blossom**, your server's dedicated head mod, hype-woman, and resident gacha addict. " \
                   "I'm here to turn your Discord server into the ultimate content creator community.\n\n" \
                   "Drop a `/help` in chat and let's go live! 📡✨"
        },
        { type: 14, spacing: 1 },
        {
          type: 10,
          content: "💻 **The Content Grind**\n" \
                   "Earn coins by streaming, posting on socials, or doing collabs with other chatters."
        },
        {
          type: 10,
          content: "🎲 **VTuber Gacha**\n" \
                   "Spend your stream revenue to summon VTubers! Build your collection and flex your pulls."
        },
        {
          type: 10,
          content: "💣 **A Little Bit of Trolling**\n" \
                   "Admins can drop bombs in chat — scramble to defuse them for a massive coin payout!"
        },
        { type: 14, spacing: 1 },
        {
          type: 10,
          content: "🛠️ Blossom is a **Kyvrixon Dev.** product. Developed by **en.vvy** and written in **.rb** (Ruby)."
        }
      ]
    }
  ]

  send_cv2(event, components)
end

# ------------------------------------------
# TRIGGERS
# ------------------------------------------
$bot.command(:about,
  description: 'Learn more about Blossom!',
  category: 'Utility'
) do |event|
  execute_about(event)
  nil
end

$bot.application_command(:about) do |event|
  execute_about(event)
end
