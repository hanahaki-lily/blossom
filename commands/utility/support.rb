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
        { type: 10, content: "## #{EMOJI_STRINGS['developer']} Support Server" },
        { type: 14, spacing: 1 },
        {
          type: 10,
          content: "Something broke? Skill issue... jk, jk. Maybe.\n" \
                   "Come yell at us in baonuki's server:\n\n" \
                   "**https://discord.gg/T9RtZY48S5**#{mom_remark(event.user.id, 'general')}"
        }
      ]
    }
  ]

  send_cv2(event, components)
end

# ------------------------------------------
# TRIGGERS
# ------------------------------------------
$bot.command(:support, aliases: [:sup],
  description: 'Get a link to the official support server',
  category: 'Utility'
) do |event|
  execute_support(event)
  nil
end

$bot.application_command(:support) do |event|
  execute_support(event)
end
