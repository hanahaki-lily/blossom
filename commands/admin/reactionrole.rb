# ==========================================
# COMMAND: reactionrole (Admin Only)
# DESCRIPTION: Set up reaction role panels and manage individual reaction roles.
# CATEGORY: Admin
# ==========================================

def execute_reactionrole(event, action, raw_args)
  unless DEV_IDS.include?(event.user.id) || event.user.permission?(:administrator, event.channel)
    return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['x_']} Access Denied" },
      { type: 14, spacing: 1 },
      { type: 10, content: "Admin only, bestie." }
    ]}])
  end

  action = action&.downcase

  case action
  when 'create'
    # b!rr create <#channel> <title> | <emoji> <@role> | <emoji> <@role> | ...
    # Parse: first arg is channel mention, then "title | emoji role | emoji role | ..."
    full_text = raw_args.join(' ')

    # Extract channel mention
    unless full_text =~ /^<#(\d+)>/
      return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
        { type: 10, content: "## #{EMOJI_STRINGS['confused']} Reaction Role Panel" },
        { type: 14, spacing: 1 },
        { type: 10, content: "**Usage:**\n`#{PREFIX}rr create #channel Title Text | emoji @Role | emoji @Role`\n\n" \
                     "**Example:**\n`#{PREFIX}rr create #roles Pick your roles! | 🎮 @Gamer | 🎵 @Music | 🎨 @Artist`" }
      ]}])
    end

    channel_id = $1.to_i
    target_channel = event.bot.channel(channel_id, event.server)
    unless target_channel
      return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
        { type: 10, content: "## #{EMOJI_STRINGS['x_']} Invalid Channel" },
        { type: 14, spacing: 1 },
        { type: 10, content: "Can't find that channel." }
      ]}])
    end

    # Remove channel mention from the text
    remaining = full_text.sub(/^<#\d+>\s*/, '')
    parts = remaining.split('|').map(&:strip)

    if parts.size < 2
      return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
        { type: 10, content: "## #{EMOJI_STRINGS['x_']} Not Enough Roles" },
        { type: 14, spacing: 1 },
        { type: 10, content: "I need a title and at least one `emoji @Role` pair separated by `|`.\n\n" \
                     "**Example:**\n`#{PREFIX}rr create #roles Pick your roles! | 🎮 @Gamer | 🎵 @Music`" }
      ]}])
    end

    title = parts[0]
    role_pairs = []

    parts[1..].each do |pair|
      tokens = pair.strip.split(/\s+/, 2)
      emoji = tokens[0]
      role_mention = tokens[1]
      next unless emoji && role_mention

      role_id = role_mention.scan(/\d+/).first&.to_i
      next unless role_id

      role = event.server.role(role_id)
      next unless role

      role_pairs << { emoji: emoji, role_id: role_id, role_name: role.name }
    end

    if role_pairs.empty?
      return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
        { type: 10, content: "## #{EMOJI_STRINGS['x_']} No Valid Roles" },
        { type: 14, spacing: 1 },
        { type: 10, content: "Couldn't parse any valid emoji + role pairs. Make sure you're mentioning real roles." }
      ]}])
    end

    # Build the panel message
    role_lines = role_pairs.map { |rp| "#{rp[:emoji]} — <@&#{rp[:role_id]}>" }.join("\n")

    panel_components = [{ type: 17, accent_color: NEON_COLORS.sample, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['neonsparkle']} #{title}" },
      { type: 14, spacing: 1 },
      { type: 10, content: "React below to grab your roles!\n\n#{role_lines}" }
    ]}]

    # Send the panel to the target channel
    body = { content: '', flags: CV2_FLAG, components: panel_components }.to_json
    response = Discordrb::API.request(
      :channels_cid_messages_mid,
      target_channel.id,
      :post,
      "#{Discordrb::API.api_base}/channels/#{target_channel.id}/messages",
      body,
      Authorization: $bot.token,
      content_type: :json
    )

    panel_msg_id = JSON.parse(response.body)['id'].to_i

    # Add reactions and save to DB
    role_pairs.each do |rp|
      begin
        Discordrb::API::Channel.create_reaction(
          $bot.token,
          target_channel.id,
          panel_msg_id,
          rp[:emoji]
        )
        sleep(0.3) # Small delay to avoid rate limits
      rescue => e
        puts "[REACTION ROLE] Failed to react with #{rp[:emoji]}: #{e.message}"
      end
      DB.add_reaction_role(event.server.id, panel_msg_id, rp[:emoji], rp[:role_id])
    end

    send_cv2(event, [{ type: 17, accent_color: 0x00FF00, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['checkmark']} Reaction Role Panel Created!" },
      { type: 14, spacing: 1 },
      { type: 10, content: "Sent to #{target_channel.mention} with **#{role_pairs.size}** reaction role#{'s' unless role_pairs.size == 1}.\nMessage ID: `#{panel_msg_id}`" }
    ]}])

  when 'add'
    # b!rr add <message_id> <emoji> <@role>
    msg_id = raw_args[0]&.to_i
    emoji = raw_args[1]
    role_mention = raw_args[2]

    unless msg_id && msg_id > 0 && emoji && role_mention
      return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
        { type: 10, content: "## #{EMOJI_STRINGS['confused']} Add Reaction Role" },
        { type: 14, spacing: 1 },
        { type: 10, content: "`#{PREFIX}rr add <message_id> <emoji> <@role>`" }
      ]}])
    end

    role_id = role_mention.scan(/\d+/).first&.to_i
    unless role_id
      return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
        { type: 10, content: "## #{EMOJI_STRINGS['x_']} Invalid Role" },
        { type: 14, spacing: 1 },
        { type: 10, content: "Mention a valid role." }
      ]}])
    end

    begin
      msg = event.channel.message(msg_id)
      msg.react(emoji)
    rescue => e
      return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
        { type: 10, content: "## #{EMOJI_STRINGS['x_']} Failed" },
        { type: 14, spacing: 1 },
        { type: 10, content: "Couldn't find that message or react to it.\n`#{e.message}`" }
      ]}])
    end

    DB.add_reaction_role(event.server.id, msg_id, emoji, role_id)
    send_cv2(event, [{ type: 17, accent_color: 0x00FF00, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['checkmark']} Reaction Role Added!" },
      { type: 14, spacing: 1 },
      { type: 10, content: "#{emoji} → <@&#{role_id}> on message `#{msg_id}`." }
    ]}])

  when 'remove'
    msg_id = raw_args[0]&.to_i
    emoji = raw_args[1]

    unless msg_id && msg_id > 0 && emoji
      return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
        { type: 10, content: "## #{EMOJI_STRINGS['confused']} Usage" },
        { type: 14, spacing: 1 },
        { type: 10, content: "`#{PREFIX}rr remove <message_id> <emoji>`" }
      ]}])
    end

    DB.remove_reaction_role(event.server.id, msg_id, emoji)
    send_cv2(event, [{ type: 17, accent_color: 0x00FF00, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['checkmark']} Reaction Role Removed" },
      { type: 14, spacing: 1 },
      { type: 10, content: "#{emoji} reaction role removed from message `#{msg_id}`." }
    ]}])

  when 'list'
    msg_id = raw_args[0]&.to_i
    unless msg_id && msg_id > 0
      return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
        { type: 10, content: "## #{EMOJI_STRINGS['confused']} Usage" },
        { type: 14, spacing: 1 },
        { type: 10, content: "`#{PREFIX}rr list <message_id>`" }
      ]}])
    end

    roles = DB.get_reaction_roles_for_message(event.server.id, msg_id)
    if roles.empty?
      return send_cv2(event, [{ type: 17, accent_color: NEON_COLORS.sample, components: [
        { type: 10, content: "## Reaction Roles" },
        { type: 14, spacing: 1 },
        { type: 10, content: "No reaction roles on that message." }
      ]}])
    end

    lines = roles.map { |r| "#{r['emoji']} → <@&#{r['role_id']}>" }.join("\n")
    send_cv2(event, [{ type: 17, accent_color: NEON_COLORS.sample, components: [
      { type: 10, content: "## Reaction Roles (Message: `#{msg_id}`)" },
      { type: 14, spacing: 1 },
      { type: 10, content: lines }
    ]}])

  else
    send_cv2(event, [{ type: 17, accent_color: NEON_COLORS.sample, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['neonsparkle']} Reaction Roles" },
      { type: 14, spacing: 1 },
      { type: 10, content: "**Create a panel** *(recommended)*\n" \
                   "`#{PREFIX}rr create #channel Title | emoji @Role | emoji @Role`\n\n" \
                   "**Add to existing message**\n" \
                   "`#{PREFIX}rr add <msg_id> <emoji> <@role>`\n\n" \
                   "**Remove / List**\n" \
                   "`#{PREFIX}rr remove <msg_id> <emoji>`\n" \
                   "`#{PREFIX}rr list <msg_id>`" }
    ]}])
  end
end

# ------------------------------------------
# TRIGGERS
# ------------------------------------------
$bot.command(:reactionrole, aliases: [:rr],
  description: 'Set up reaction roles (Admin Only)',
  category: 'Admin'
) do |event, action, *args|
  execute_reactionrole(event, action, args)
  nil
end
