# ==========================================
# COMMAND: premium
# DESCRIPTION: View your premium status and perks.
# CATEGORY: Utility
# ==========================================

KOFI_PAGE_URL = ENV.fetch('KOFI_PAGE_URL', 'https://ko-fi.com/envvy')

def execute_premium(event)
  uid = event.user.id
  is_sub = is_premium?(event.bot, uid)
  linked_email = DB.get_kofi_link(uid)
  sub_info = DB.get_premium_sub(uid)
  is_lifetime = DB.is_lifetime_premium?(uid)

  # Build status section
  if is_lifetime
    status_text = "#{EMOJI_STRINGS['crown']} **Lifetime Premium**\nYou've got the eternal VIP pass. No expiry. No limits. Legendary."
  elsif sub_info && sub_info['active'].to_i == 1 && Time.parse(sub_info['expires_at']) > Time.now
    days_left = ((Time.parse(sub_info['expires_at']) - Time.now) / 86400).ceil
    status_text = "#{EMOJI_STRINGS['checkmark']} **Active** — #{days_left} day#{'s' if days_left != 1} remaining"
  elsif is_sub
    status_text = "#{EMOJI_STRINGS['checkmark']} **Active** via server role"
  else
    status_text = "#{EMOJI_STRINGS['x_']} **Not Active**"
  end

  # Build link section
  if linked_email
    parts = linked_email.split('@')
    masked = parts[0].length > 3 ? "#{parts[0][0..2]}***@#{parts[1]}" : "***@#{parts[1]}"
    link_text = "#{EMOJI_STRINGS['checkmark']} Linked to **#{masked}**"
  else
    link_text = "#{EMOJI_STRINGS['x_']} Not linked — use `#{PREFIX}link set your@email.com`"
  end

  perks = [
    "#{EMOJI_STRINGS['s_coin']} **+10% bonus coins** on every payout",
    "#{EMOJI_STRINGS['neonsparkle']} **50% shorter cooldowns** on economy commands",
    "#{EMOJI_STRINGS['level_heart']} **1.5x XP gain** per message",
    "#{EMOJI_STRINGS['prisma']} **Prisma currency** earnings",
    "#{EMOJI_STRINGS['rng_manipulator']} **Gacha pity system** — guaranteed rare after 30 pulls",
    "#{EMOJI_STRINGS['sparkle']} **Shiny Ascended** card variants",
    "🎰 **Daily Wheel reroll** for a second chance",
    "🎨 **Custom profile** — bio, color, 3 favorite cards",
    "🔔 **Cooldown reminders** via DM",
    "#{EMOJI_STRINGS['crown']} **Premium badge** on leaderboards"
  ].join("\n")

  components = [{ type: 17, accent_color: 0xBF40BF, components: [
    { type: 10, content: "## #{EMOJI_STRINGS['prisma']} Neon Arcade Premium" },
    { type: 14, spacing: 1 },
    { type: 10, content: "**Status:** #{status_text}" },
    { type: 10, content: "**Ko-fi:** #{link_text}" },
    { type: 14, spacing: 1 },
    { type: 10, content: "### Perks" },
    { type: 10, content: perks }
  ]}]

  # Add subscribe button if not premium
  unless is_sub
    components[0][:components] << { type: 14, spacing: 1 }
    components[0][:components] << { type: 10, content: "-# Subscribe on Ko-fi to unlock all perks!" }
    components[0][:components] << {
      type: 1, components: [{
        type: 2, style: 5, label: 'Subscribe on Ko-fi', url: KOFI_PAGE_URL, emoji: { name: '☕' }
      }]
    }
  end

  send_cv2(event, components)
end

# ------------------------------------------
# TRIGGERS
# ------------------------------------------
$bot.command(:premium, aliases: [:sub, :subscribe, :vip],
  description: 'View your premium status and perks!',
  category: 'Utility'
) do |event|
  execute_premium(event)
  nil
end

$bot.application_command(:premium) do |event|
  execute_premium(event)
end
