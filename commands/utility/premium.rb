# ==========================================
# COMMAND: premium
# DESCRIPTION: Short premium perks teaser + Ko-fi link (KOFI_PAGE_URL).
# CATEGORY: Utility
# ==========================================

def execute_premium(event)
  uid = event.user.id
  url = ENV['KOFI_PAGE_URL'].to_s.strip

  lines = [
    "- **Timers** — 50% shorter cooldowns on work, stream, post & fish.",
    "- **Coins** — +10% on earns; happy hour hits **3×** for subs vs **2×** free.",
    "- **Extras** — Prisma on daily, gacha pity/shiny boosts, arcade rerolls, `/autoclaim`, `/invest`—stacked.",
    url.empty? ? nil : "- **Ko-fi:** #{url}"
  ].compact

  body = "**Neon Arcade VIP — cheat sheet**\n#{lines.join("\n")}"

  footer = if url.empty?
             "\n\n*No Ko-fi URL on this host (`KOFI_PAGE_URL`). Still flexing the perks tho.*#{mom_remark(uid, 'general')}"
           else
             "\n\n_Subscribe via Ko-fi, link Discord (Ko‑fi Discord rewards → same subscriber role Blossom checks), perks flip on._#{mom_remark(uid, 'general')}"
           end

  send_cv2(event, [{ type: 17, accent_color: NEON_COLORS.sample, components: [
                      { type: 10, content: "## #{EMOJI_STRINGS['crown']} Blossom Premium" },
                      { type: 14, spacing: 1 },
                      { type: 10, content: "#{body}#{footer}" }
                    ] }])
end

# ------------------------------------------
# TRIGGERS
# ------------------------------------------
$bot.command(:premium,
             aliases: %i[vip supporter subscribe],
             description: 'VIP perks teaser + Ko-fi link',
             category: 'Utility') do |event|
  execute_premium(event)
  nil
end

$bot.application_command(:premium) do |event|
  execute_premium(event)
end
