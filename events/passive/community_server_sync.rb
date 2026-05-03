# ==========================================
# EVENT: Community guild metadata sync
# DESCRIPTION: Keeps community_levels.server_name aligned with Discord when
# a guild is updated (rename, etc.). Without this, Global Communities only
# refreshed names on boot, pool XP writes, or dcommxp.
# ==========================================

$bot.server_update do |event|
  s = event.server
  next unless s

  stats = DB.get_community_level(s.id)
  DB.update_community_level(s.id, s.name, stats['xp'], stats['level'])
end
