# ==========================================
# COMMAND: marry / divorce
# DESCRIPTION: Marriage system. Partner up for profile flair and daily bonuses.
# CATEGORY: Fun
# ==========================================

MARRIAGE_DAILY_BONUS = 50

def execute_marry(event, target_user)
  uid = event.user.id
  target_id = target_user.id

  if uid == target_id
    return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['x_']} Marriage" },
      { type: 14, spacing: 1 },
      { type: 10, content: "You can't marry yourself. That's just sad, chat." }
    ]}])
  end

  if target_user.bot_account?
    return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['x_']} Marriage" },
      { type: 14, spacing: 1 },
      { type: 10, content: "You can't marry a bot. I mean, I'm flattered, but no." }
    ]}])
  end

  # Check if either party is already married
  existing = DB.get_marriage(uid)
  if existing
    return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['x_']} Already Married" },
      { type: 14, spacing: 1 },
      { type: 10, content: "You're already married! Divorce first if you want to move on. (`#{PREFIX}divorce`)" }
    ]}])
  end

  target_existing = DB.get_marriage(target_id)
  if target_existing
    return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['x_']} They're Taken" },
      { type: 14, spacing: 1 },
      { type: 10, content: "**#{target_user.display_name}** is already married. You're too late, chat." }
    ]}])
  end

  # Create proposal
  proposal_id = "proposal_#{uid}_#{target_id}"
  ACTIVE_PROPOSALS[proposal_id] = { from: uid, to: target_id }

  send_cv2(event, [{ type: 17, accent_color: 0xFF69B4, components: [
    { type: 10, content: "## #{EMOJI_STRINGS['rainbowheart']} Marriage Proposal!" },
    { type: 14, spacing: 1 },
    { type: 10, content: "#{target_user.mention}, **#{event.user.display_name}** is proposing to you!! #{EMOJI_STRINGS['hearts']}\n\nDo you accept? *(Both partners get +#{MARRIAGE_DAILY_BONUS} bonus coins on daily claims!)*" },
    { type: 1, components: [
      { type: 2, style: 3, label: "I Do!", custom_id: "marry_accept_#{uid}_#{target_id}", emoji: { name: '💍' } },
      { type: 2, style: 4, label: "No Thanks", custom_id: "marry_decline_#{uid}_#{target_id}" }
    ]}
  ]}])
end

def execute_divorce(event)
  uid = event.user.id
  marriage = DB.get_marriage(uid)

  # Dev ID is trapped forever. No escape. Mom said so.
  unless marriage && uid != DEV_ID
    return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['x_']} Divorce" },
      { type: 14, spacing: 1 },
      { type: 10, content: "You're not married. Can't divorce what doesn't exist." }
    ]}])
  end

  DB.delete_marriage(uid)
  send_cv2(event, [{ type: 17, accent_color: 0x808080, components: [
    { type: 10, content: "## 💔 Divorced" },
    { type: 14, spacing: 1 },
    { type: 10, content: "It's over. You and <@#{marriage[:partner]}> are no longer married.\n*Awkward...*" }
  ]}])
end

# ------------------------------------------
# TRIGGERS
# ------------------------------------------
$bot.command(:marry,
  description: 'Propose to someone!',
  category: 'Fun'
) do |event|
  target = event.message.mentions.first
  unless target
    send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['x_']} Marriage" },
      { type: 14, spacing: 1 },
      { type: 10, content: "Mention someone to propose! `#{PREFIX}marry @user`" }
    ]}])
    next
  end
  execute_marry(event, target)
  nil
end

$bot.application_command(:marry) do |event|
  target = event.bot.user(event.options['user'].to_i)
  execute_marry(event, target)
end

$bot.command(:divorce,
  description: 'End your marriage',
  category: 'Fun'
) do |event|
  execute_divorce(event)
  nil
end

$bot.application_command(:divorce) do |event|
  execute_divorce(event)
end
