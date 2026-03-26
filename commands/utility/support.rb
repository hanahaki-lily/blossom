# ==========================================
# COMMAND: support
# DESCRIPTION: Get a link to the official support server for help and community.
# CATEGORY: Utility
# ==========================================

def execute_support(event)
  components = [
    {
      type: 17,
      accent_color: 0x5865F2,
      components: [
        { type: 10, content: "## 🛠️ Support Server" },
        { type: 14, spacing: 1 },
        {
          type: 10,
          content: "Need assistance, have questions, or want to report a bug?\n" \
                   "Join the Tsukiyo Server here:\n\n" \
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
$bot.command(:support,
  description: 'Get a link to the official support server',
  category: 'Utility'
) do |event|
  execute_support(event)
  nil
end

$bot.application_command(:support) do |event|
  execute_support(event)
end
