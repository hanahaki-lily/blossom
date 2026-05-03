# ==========================================
# COMMAND: drules
# DESCRIPTION: Developer posts standard server rules embed to a channel.
# CATEGORY: Developer
# ==========================================

DRULES_USAGE = "**Usage:** `#{PREFIX}drules #channel`\nPosts Blossom's default rules embed in that channel (same server only)."

def drules_channel_id_from_arg(raw)
  return nil if raw.nil?
  s = raw.to_s.strip
  if (m = s.match(/\A<#(\d+)>\z/))
    m[1].to_i
  elsif s.match?(/\A\d{17,20}\z/)
    s.to_i
  else
    nil
  end
end

def drules_embed_for_channel
  intro = "Welcome to the **Neon Arcade** \u2014 I'm Blossom, your slightly unhinged host. These rules keep chat playable for everyone. Read them, don't speedrun a ban, and we're golden."

  fields = [
    { name: "\u2661 Rule 1 \u2661", value: "Be **respectful** and **kind**. We're a community, not a free-for-all PvP lobby. Drama tourists can leave their toxicity at the door." },
    { name: "\u2661 Rule 2 \u2661", value: "No **spam**, and don't dump random memes / videos / images unless they actually fit the conversation \u2014 unless the channel is *literally* for that. Mods can yeet off-topic junk without a debate panel." },
    { name: "\u2661 Rule 3 \u2661", value: "No **hate**, slurs, or edgy \u201Cjust jokes\u201D content. Being offensive isn't comedy; it's a skill issue. Keep it chill." },
    { name: "\u2661 Rule 4 \u2661", value: "**No NSFW** — no lewd jokes, references, links, or 18+ media. This isn't that kind of arcade." },
    { name: "\u2661 Rule 5 \u2661", value: "Avoid topics that wig people out or get heated fast (**politics, alcohol/drugs**, etc.). **Trauma dumping / heavy venting** belongs in a **designated vent channel** if you have one \u2014 not random chat. Respect boundaries." },
    { name: "\u2661 Rule 6 \u2661", value: "Don't joke about stuff that can **trigger** people (**self-harm, threats**, etc.) \u2014 **including GIFs and emoji**. Not cute, not clever." },
    { name: "\u2661 Rule 7 \u2661", value: "**No self-promo** or random advertising. Sharing **your art** is fine when it's part of the convo \u2014 not when you're treating the server like a billboard." },
    { name: "\u2661 Rule 8 \u2661", value: "Don't litigate **moderation** in public (**bans, mutes, warnings**). Take it to **modmail / tickets / a mod** like an adult. Nobody earns pity points in #general." },
    { name: "\u2661 Rule 9 \u2661", value: "**Under 18:** please don't post **selfies** or turn on **webcam in VC** here. Stay safe; the internet's weird enough." },
    { name: "\u2661 Rule 10 \u2661", value: "**English only** in chat so mods and everyone else can follow along. Thanks for keeping the machine-readable." },
    { name: "\u2661 Rule 11 \u2661", value: "**Don't ping / mass-mention @staff, @mods, or individual mods** for routine stuff. Use tickets/support channels or ask calmly in chat. Pings are for **real emergencies** \u2014 mods aren't NPC quest givers. (Neither am I. I just work here.)" }
  ]

  embed = Discordrb::Webhooks::Embed.new
  embed.title = "\u{1F338} Server Rules"
  embed.description = intro
  embed.color = NEON_COLORS.sample
  embed.timestamp = Time.now
  fields.each { |f| embed.add_field(name: f[:name], value: f[:value], inline: false) }
  embed
end

def execute_drules(event, channel_raw)
  unless DEV_IDS.include?(event.user.id)
    return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['x_']} Dev Only" },
      { type: 14, spacing: 1 },
      { type: 10, content: "Nice try, chat \u2014 this one's for **my creator / devs** only." }
    ]}])
  end

  unless event.server
    return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['x_']} Server Only" },
      { type: 14, spacing: 1 },
      { type: 10, content: "Run `#{PREFIX}drules` **from a server channel** so I know where home is.\n\n#{DRULES_USAGE}#{family_remark(event.user.id, 'dev')}" }
    ]}])
  end

  cid = drules_channel_id_from_arg(channel_raw)
  unless cid
    return send_cv2(event, [{ type: 17, accent_color: 0xFFA500, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['confused']} Which Channel?" },
      { type: 14, spacing: 1 },
      { type: 10, content: "#{DRULES_USAGE}#{family_remark(event.user.id, 'dev')}" }
    ]}])
  end

  target = event.bot.channel(cid)
  unless target && target.respond_to?(:server) && target.server&.id == event.server.id
    return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['confused']} Bad Channel" },
      { type: 14, spacing: 1 },
      { type: 10, content: "Need a channel **in this server** that I can see.\n\n#{DRULES_USAGE}#{family_remark(event.user.id, 'dev')}" }
    ]}])
  end

  embed = drules_embed_for_channel
  embed.footer = Discordrb::Webhooks::EmbedFooter.new(
    text: "Rules posted by #{event.user.display_name}",
    icon_url: event.user.avatar_url
  )

  begin
    target.send_message(nil, false, embed)
  rescue StandardError => e
    return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['error']} Send Failed" },
      { type: 14, spacing: 1 },
      { type: 10, content: "Couldn't post \u2014 check **Send Messages** / **Embed Links** in #{target.mention}.\n`#{e.class}: #{e.message}`#{family_remark(event.user.id, 'dev')}" }
    ]}])
  end

  send_cv2(event, [{ type: 17, accent_color: 0x00FF00, components: [
    { type: 10, content: "## #{EMOJI_STRINGS['checkmark']} Rules Deployed" },
    { type: 14, spacing: 1 },
    { type: 10, content: "Full rules embed is up in #{target.mention}. Try not to make me write a sequel called *\u201CRule 12: Seriously?\u201D*#{family_remark(event.user.id, 'dev')}" }
  ]}])
end

$bot.command(:drules,
  description: 'Post default server rules embed (Dev Only)',
  category: 'Developer'
) do |event, channel_mention|
  execute_drules(event, channel_mention)
  nil
end
