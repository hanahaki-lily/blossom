# ==========================================
# COMMAND: serverinfo
# DESCRIPTION: Displays technical stats and the "Community Level" for the current server.
# CATEGORY: Utility / Social
# ==========================================

# ------------------------------------------
# LOGIC: Server Info Execution
# ------------------------------------------
def execute_serverinfo(event)
  # 1. Validation: Ensure the command is not run in DMs
  # Server metadata and Community XP require a guild context.
  unless event.server
    return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['error']} Error" },
      { type: 14, spacing: 1 },
      { type: 10, content: "You gotta be in a server for this one, chief." }
    ]}])
  end

  # 2. Initialization: Gather basic server metadata
  server = event.server
  owner = server.owner
  created_time = server.creation_time.to_i

  # 3. Data Retrieval: Fetch the server's specific "Community Level" from the DB
  comm_stats = DB.get_community_level(server.id)
  current_level = comm_stats['level'].to_i
  current_xp = comm_stats['xp'].to_i
  
  # 4. Math: Calculate the quadratic XP curve for the next level
  # Formula: (100 * Level^2) + (1000 * Level)
  next_level_xp = (100 * (current_level ** 2)) + (1000 * current_level)

  # 5. Messaging: Construct and send the final Server Info CV2 message
  # Uses Section (type 9) + Thumbnail accessory (type 11) for a clean icon-beside-text layout
  icon_url = server.icon_url || ''

  send_cv2(event, [{ type: 17, accent_color: NEON_COLORS.sample, components: [
    { type: 9, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['info']} #{server.name}" },
      { type: 10, content: "Alright, here's what we're working with, chat." }
    ], accessory: { type: 11, media: { url: icon_url } } },
    { type: 14, spacing: 1 },
    { type: 10, content: "#{EMOJI_STRINGS['crown']} **Server Owner**\n#{owner ? owner.mention : 'Unknown'}" },
    { type: 10, content: "👥 **Total Members**\n#{server.member_count}" },
    { type: 10, content: "#{EMOJI_STRINGS['neonsparkle']} **Community Rank**\nLevel **#{current_level}** — #{current_xp} / #{next_level_xp} XP" },
    { type: 10, content: "#{EMOJI_STRINGS['stream']} **Created**\n<t:#{created_time}:D> (<t:#{created_time}:R>)#{mom_remark(event.user.id, 'general')}" }
  ]}])
end

# ------------------------------------------
# TRIGGER: Prefix Command (b!serverinfo)
# ------------------------------------------
$bot.command(:serverinfo, aliases: [:si, :server],
  description: 'Displays information about the current server', 
  category: 'Utility'
) do |event|
  execute_serverinfo(event)
  nil # Suppress default return
end

# ------------------------------------------
# TRIGGER: Slash Command (/serverinfo)
# ------------------------------------------
$bot.application_command(:serverinfo) do |event|
  execute_serverinfo(event)
end