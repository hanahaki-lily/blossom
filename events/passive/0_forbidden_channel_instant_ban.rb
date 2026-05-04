# ==========================================
# EVENT: Forbidden Channel — Instant Delete + Ban
# DESCRIPTION: Messages in FORBIDDEN_INSTANT_BAN_CHANNEL_ID are removed and
# the author is banned from the server. Skips bots and developer accounts.
# Requires: Manage Messages + Ban Members (and hierarchy above the member).
# Filename prefix keeps this loaded before other passive message handlers.
# ==========================================

$bot.message do |event|
  next unless event.server
  next unless event.channel.id == FORBIDDEN_INSTANT_BAN_CHANNEL_ID
  next if event.user.bot_account?
  next if DEV_IDS.include?(event.user.id)

  begin
    event.message.delete
  rescue StandardError
    # Missing perms or message already gone
  end

  begin
    event.server.ban(event.user.id, 0, reason: 'Automatic: posting in a no-post channel')
    log_mod_action(
      event.bot,
      event.server.id,
      '🔨 Auto-ban (forbidden channel)',
      "**User:** #{event.user.mention} (#{event.user.distinct})\n**Channel:** <##{event.channel.id}>",
      0x8B0000
    )
  rescue StandardError => e
    puts "[FORBIDDEN CHANNEL BAN] #{e.class}: #{e.message}"
  end
end
