# ==========================================
# COMMAND: premium
# DESCRIPTION: Showcases the benefits of supporting Blossom via server boosting.
# CATEGORY: Utility
# ==========================================

def execute_premium(event)
  components = [
    {
      type: 17,
      accent_color: 0x00FFFF,
      components: [
        { type: 10, content: "## 💎 Blossom Premium" },
        { type: 14, spacing: 1 },
        {
          type: 10,
          content: "Support Blossom's development and unlock amazing global perks!\n\n" \
                   "**💎 Premium Bonuses:**\n" \
                   "⏱️ **50% Faster Cooldowns** on `!work`, `!stream`, and `!post`\n" \
                   "💰 **+10% Coin Boost** from all sources\n" \
                   "🍀 **Boosted Gacha Odds** (higher chance for Rares, Legendaries, and Goddesses)\n" \
                   "✨ **1% Secret Chance** to instantly pull a Shiny Ascended character!"
        },
        { type: 14, spacing: 1 },
        {
          type: 10,
          content: "To unlock these perks, join the Tsukiyo Server and boost it!\n" \
                   "**https://discord.gg/tsukiyo**"
        }
      ]
    }
  ]

  send_cv2(event, components)
end

# ------------------------------------------
# TRIGGERS
# ------------------------------------------
$bot.command(:premium,
  description: 'View the benefits of Blossom Premium!',
  category: 'Utility'
) do |event|
  execute_premium(event)
  nil
end

$bot.application_command(:premium) do |event|
  execute_premium(event)
end
