# ==========================================
# EVENT: Reaction Role Handlers
# DESCRIPTION: Grants/removes roles when users react/unreact on configured messages.
# ==========================================

$bot.reaction_add do |event|
  next unless event.server

  # Skip bot reactions (use ID check since .bot_account? may not work on lightweight objects)
  next if event.user.id == event.bot.profile.id

  # Try both the emoji name and the full unicode representation
  emoji_key = event.emoji.name
  role_id = DB.get_reaction_role(event.server.id, event.message.id, emoji_key)

  # Also try the emoji's to_s in case of encoding differences
  role_id ||= DB.get_reaction_role(event.server.id, event.message.id, event.emoji.to_s)

  next unless role_id

  begin
    member = event.server.member(event.user.id)
    role = event.server.role(role_id)
    if member && role
      member.add_role(role)
      puts "[REACTION ROLE] Granted #{role.name} to #{member.display_name}"
    end
  rescue => e
    puts "[REACTION ROLE ERROR] Add: #{e.message}"
  end
end

$bot.reaction_remove do |event|
  next unless event.server
  next if event.user.id == event.bot.profile.id

  emoji_key = event.emoji.name
  role_id = DB.get_reaction_role(event.server.id, event.message.id, emoji_key)
  role_id ||= DB.get_reaction_role(event.server.id, event.message.id, event.emoji.to_s)

  next unless role_id

  begin
    member = event.server.member(event.user.id)
    role = event.server.role(role_id)
    if member && role
      member.remove_role(role)
      puts "[REACTION ROLE] Removed #{role.name} from #{member.display_name}"
    end
  rescue => e
    puts "[REACTION ROLE ERROR] Remove: #{e.message}"
  end
end
