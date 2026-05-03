# ==========================================
# EVENT: Hub guild join / leave logger
# DESCRIPTION: Posts a Components V2 card to the owner hub when Blossom
# joins or leaves (kick/ban/leave) any server. Guild delete only carries
# an id in discordrb, so we cache metadata on create/update/ready.
# ==========================================

HUB_GUILD_META_CACHE = {}

def hub_safe_name(str)
  str.to_s.gsub('`', "'").gsub("\n", ' ').strip
end

def stash_hub_guild_meta(server)
  return unless server

  owner = server.owner
  owner_name = owner ? owner.username.to_s : 'Unknown'
  HUB_GUILD_META_CACHE[server.id] = {
    name: server.name.to_s,
    icon_url: server.icon_url.to_s,
    member_count: server.member_count,
    owner_username: owner_name,
    created_ts: server.creation_time.to_i
  }
end

def hub_guild_totals(bot)
  servers = bot.servers.values
  [servers.size, servers.sum(&:member_count)]
end

def post_hub_guild_cv2(bot, accent_color:, action_label:, display_name:, lines:, icon_url:)
  chan_id = HUB_GUILD_LOG_CHANNEL_ID
  return if chan_id.to_i.zero?

  thumb = icon_url.to_s.strip
  thumb = 'https://cdn.discordapp.com/embed/avatars/0.png' if thumb.empty?

  nm = hub_safe_name(display_name)
  body_inner = [
    { type: 9, components: [
      { type: 10, content: "## #{action_label} (#{nm})" },
      { type: 10, content: lines }
    ], accessory: { type: 11, media: { url: thumb } } }
  ]
  body = {
    content: '', flags: CV2_FLAG,
    components: [{ type: 17, accent_color: accent_color, components: body_inner }],
    allowed_mentions: { parse: [] }
  }.to_json

  Discordrb::API.request(
    :channels_cid_messages_mid,
    chan_id,
    :post,
    "#{Discordrb::API.api_base}/channels/#{chan_id}/messages",
    body,
    Authorization: bot.token,
    content_type: :json
  )
rescue StandardError => e
  puts "[HUB-GUILD-LOG] #{e.class}: #{e.message}"
end

def log_hub_guild_join(bot, server)
  return unless server

  stash_hub_guild_meta(server)
  arcades, users = hub_guild_totals(bot)
  sid = server.id
  owner = server.owner
  owner_name = owner ? owner.username.to_s : 'Unknown'
  created = server.creation_time.to_i
  lines = [
    "Members: #{server.member_count}",
    "Owner: #{hub_safe_name(owner_name)}",
    "Created: <t:#{created}:D> (<t:#{created}:R>)",
    "ID: `#{sid}`",
    '',
    "Now in #{arcades} arcades with #{users} total users"
  ].join("\n")

  post_hub_guild_cv2(
    bot,
    accent_color: 0x00FF00,
    action_label: 'Joined Server',
    display_name: server.name,
    lines: lines,
    icon_url: server.icon_url
  )
end

def log_hub_guild_leave(bot, sid, meta)
  sid = sid.to_i
  meta ||= {}
  arcades, users = hub_guild_totals(bot)

  raw_name = meta[:name] || meta['name']
  name = !raw_name.to_s.strip.empty? ? raw_name.to_s.strip : "Guild #{sid}"
  members = meta[:member_count] || meta['member_count']
  members_str = members.nil? ? '—' : members.to_s
  owner_name = meta[:owner_username] || meta['owner_username'] || '—'
  created_ts = meta[:created_ts] || meta['created_ts']
  created_str = if created_ts.to_i.positive?
                  c = created_ts.to_i
                  "<t:#{c}:D> (<t:#{c}:R>)"
                else
                  '—'
                end

  lines = [
    "Members: #{members_str}",
    "Owner: #{hub_safe_name(owner_name)}",
    "Created: #{created_str}",
    "ID: `#{sid}`",
    '',
    "Now in #{arcades} arcades with #{users} total users"
  ].join("\n")

  icon = (meta[:icon_url] || meta['icon_url']).to_s

  post_hub_guild_cv2(
    bot,
    accent_color: 0xFF6600,
    action_label: 'Left Server',
    display_name: name,
    lines: lines,
    icon_url: icon
  )
end

$bot.ready do |event|
  event.bot.servers.each_value { |s| stash_hub_guild_meta(s) }
end

$bot.server_create do |event|
  next unless event.server

  log_hub_guild_join(event.bot, event.server)
end

$bot.server_update do |event|
  stash_hub_guild_meta(event.server) if event.server
end

$bot.server_delete do |event|
  sid = event.server
  next unless sid.is_a?(Integer) && sid.positive?

  meta = HUB_GUILD_META_CACHE.delete(sid)
  log_hub_guild_leave(event.bot, sid, meta)
end
