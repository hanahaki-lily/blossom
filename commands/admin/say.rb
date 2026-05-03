# ==========================================
# COMMAND: say
# DESCRIPTION: Admin posts an embed (message body) to another channel in the server.
# CATEGORY: Admin
# ==========================================

SAY_USAGE = "**Usage:** `#{PREFIX}say #channel <your message>`\nYou can paste **multiple paragraphs** — line breaks are preserved.\nExample: `#{PREFIX}say #announcements Line one.\n\nLine two after a blank line.`"

def say_channel_id_from_arg(raw)
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

# discordrb passes `*args` split on whitespace — newlines become separate tokens and
# `join(' ')` destroys paragraph breaks. Parse the real message body from content.
def parse_say_message(event)
  raw = event.message.content.to_s
  prefix = PREFIX.to_s
  return [nil, nil] unless raw.start_with?(prefix)

  tail = raw[prefix.length..].lstrip
  return [nil, nil] unless tail.match?(/\Asay\b/i)

  tail = tail.sub(/\Asay\b\s*/i, '')
  return [nil, nil] if tail.empty?

  if (m = tail.match(/\A(<#\d+>|[0-9]{17,20})\s*/))
    channel_token = m[1]
    body = tail[m.end(0)..].to_s
    [channel_token, body]
  else
    [nil, nil]
  end
end

def execute_say(event, channel_raw, text)
  unless event.server
    return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['x_']} Wrong Lobby" },
      { type: 14, spacing: 1 },
      { type: 10, content: "Run this from a **server** channel — I need to know which arcade we're posting to.#{mom_remark(event.user.id, 'admin')}" }
    ]}])
  end

  unless event.user.permission?(:administrator, event.channel) || DEV_IDS.include?(event.user.id)
    return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['x_']} Permission Denied" },
      { type: 14, spacing: 1 },
      { type: 10, content: "Administrator only. I'm not your personal broadcast system unless you're actually running the show.#{mom_remark(event.user.id, 'admin')}" }
    ]}])
  end

  cid = say_channel_id_from_arg(channel_raw)
  unless cid
    return send_cv2(event, [{ type: 17, accent_color: 0xFFA500, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['confused']} Need a Channel" },
      { type: 14, spacing: 1 },
      { type: 10, content: "Drop a **#channel** mention (or channel ID), then your message.\n\n#{SAY_USAGE}#{mom_remark(event.user.id, 'admin')}" }
    ]}])
  end

  body = text.to_s.gsub("\r\n", "\n").strip
  if body.empty?
    return send_cv2(event, [{ type: 17, accent_color: 0xFFA500, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['confused']} Say Something" },
      { type: 14, spacing: 1 },
      { type: 10, content: "Embed's gotta have text, genius.\n\n#{SAY_USAGE}#{mom_remark(event.user.id, 'admin')}" }
    ]}])
  end

  if body.size > 4096
    return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['x_']} Too Long" },
      { type: 14, spacing: 1 },
      { type: 10, content: "Discord caps embed descriptions at **4096** characters. Trim it or split into two posts.#{mom_remark(event.user.id, 'admin')}" }
    ]}])
  end

  target = event.bot.channel(cid)
  unless target && target.respond_to?(:server) && target.server&.id == event.server.id
    return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['confused']} Channel Not Found" },
      { type: 14, spacing: 1 },
      { type: 10, content: "That channel isn't in **this** server or I can't see it. Double-check the mention.#{mom_remark(event.user.id, 'admin')}" }
    ]}])
  end

  embed = Discordrb::Webhooks::Embed.new
  embed.description = body
  embed.color = NEON_COLORS.sample
  embed.timestamp = Time.now
  embed.footer = Discordrb::Webhooks::EmbedFooter.new(
    text: "Posted by #{event.user.display_name}",
    icon_url: event.user.avatar_url
  )

  begin
    target.send_message(nil, false, embed)
  rescue StandardError => e
    return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['error']} Couldn't Send" },
      { type: 14, spacing: 1 },
      { type: 10, content: "Discord blocked me — probably missing **Send Messages** or **Embed Links** in #{target.mention}.\n`#{e.class}: #{e.message}`#{mom_remark(event.user.id, 'admin')}" }
    ]}])
  end

  send_cv2(event, [{ type: 17, accent_color: 0x00FF00, components: [
    { type: 10, content: "## #{EMOJI_STRINGS['checkmark']} Delivered" },
    { type: 14, spacing: 1 },
    { type: 10, content: "Embed's live in #{target.mention}. Don't make me regret giving you the PA mic.#{mom_remark(event.user.id, 'admin')}" }
  ]}])
end

$bot.command(:say,
  description: 'Post an embed announcement to a channel (Admin)',
  category: 'Admin'
) do |event, *_legacy_args|
  channel_raw, body = parse_say_message(event)
  execute_say(event, channel_raw, body)
  nil
end
