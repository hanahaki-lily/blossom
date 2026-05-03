# ==========================================
# COMMAND: dcommxp (Developer Only)
# DESCRIPTION: Adjust this server's community (pooled) XP and level — not per-user XP.
# CATEGORY: Developer
# ==========================================

DCOMMXP_USAGE = "**Usage:** (server only)\n" \
                "`#{PREFIX}dcommxp add <amount>` — Add community XP (level recalculated from total)\n" \
                "`#{PREFIX}dcommxp remove <amount>` — Remove community XP\n" \
                "`#{PREFIX}dcommxp set <amount>` — Set total community XP\n" \
                "`#{PREFIX}dcommxp level <n>` — Set community level (XP unchanged)"

def execute_dcommxp(event, action, amount)
  unless DEV_IDS.include?(event.user.id)
    return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['x_']} Permission Denied" },
      { type: 14, spacing: 1 },
      { type: 10, content: "Only my creator can use this." }
    ]}])
  end

  unless event.server
    return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['x_']} Server Only" },
      { type: 14, spacing: 1 },
      { type: 10, content: "Community levels are per server — run this in a guild." }
    ]}])
  end

  if action.nil?
    return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['confused']} How Does This Work?" },
      { type: 14, spacing: 1 },
      { type: 10, content: DCOMMXP_USAGE }
    ]}])
  end

  unless %w[add remove set level].include?(action.downcase)
    return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['confused']} Invalid Action" },
      { type: 14, spacing: 1 },
      { type: 10, content: "**#{action}** isn't valid. Use `add`, `remove`, `set`, or `level`.\n\n#{DCOMMXP_USAGE}" }
    ]}])
  end

  if amount.nil? || amount == 0
    return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['confused']} How Much?" },
      { type: 14, spacing: 1 },
      { type: 10, content: "Give me a non-zero number.\n\n#{DCOMMXP_USAGE}" }
    ]}])
  end

  sid = event.server.id
  name = event.server.name
  stats = DB.get_community_level(sid)
  cur_xp = stats['xp'].to_i
  cur_level = stats['level'].to_i

  case action.downcase
  when 'add'
    new_xp = cur_xp + amount.abs
    new_level = DB.community_level_from_total_xp(new_xp)
  when 'remove'
    new_xp = [cur_xp - amount.abs, 0].max
    new_level = DB.community_level_from_total_xp(new_xp)
  when 'set'
    new_xp = amount.abs
    new_level = DB.community_level_from_total_xp(new_xp)
  when 'level'
    new_level = [amount.abs, 1].max
    new_xp = cur_xp
  end

  DB.update_community_level(sid, name, new_xp, new_level)
  next_at = DB.community_xp_threshold(new_level)

  send_cv2(event, [{ type: 17, accent_color: 0x00FF00, components: [
    { type: 10, content: "## #{EMOJI_STRINGS['developer']} Community XP Override" },
    { type: 14, spacing: 1 },
    { type: 10, content: "**#{name}** — Level **#{new_level}**, **#{new_xp}** cumulative XP (next threshold at **#{next_at}** XP for this level).#{mom_remark(event.user.id, 'dev')}" }
  ]}])
end

$bot.command(:dcommxp, aliases: [:dcomm, :communityxp],
             description: 'Adjust community (server) XP/level — not users (Dev Only)',
             category: 'Developer'
) do |event, action, amount|
  execute_dcommxp(event, action, amount.nil? ? nil : amount.to_i)
  nil
end
