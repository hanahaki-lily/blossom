# ==========================================
# EVENT: Marriage Accept/Decline Buttons
# ==========================================

$bot.button(custom_id: /^marry_accept_/) do |event|
  parts = event.custom_id.split('_')
  from_id = parts[2].to_i
  to_id = parts[3].to_i
  proposal_id = "proposal_#{from_id}_#{to_id}"

  if event.user.id != to_id
    next event.respond(content: "#{EMOJI_STRINGS['x_']} This proposal isn't for you, chat.", ephemeral: true)
  end

  unless ACTIVE_PROPOSALS.key?(proposal_id)
    next event.respond(content: "#{EMOJI_STRINGS['x_']} This proposal expired or was already answered.", ephemeral: true)
  end

  ACTIVE_PROPOSALS.delete(proposal_id)

  # Double-check neither got married while waiting
  if DB.get_marriage(from_id) || DB.get_marriage(to_id)
    next event.update_message(
      content: '', flags: CV2_FLAG,
      components: [{ type: 17, accent_color: 0xFF0000, components: [
        { type: 10, content: "## #{EMOJI_STRINGS['x_']} Marriage Failed" },
        { type: 14, spacing: 1 },
        { type: 10, content: "Someone got married while this proposal was pending! Awkward timing." }
      ]}]
    )
  end

  DB.create_marriage(from_id, to_id)

  event.update_message(
    content: '', flags: CV2_FLAG,
    components: [{ type: 17, accent_color: 0xFF69B4, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['rainbowheart']} Just Married! #{EMOJI_STRINGS['hearts']}" },
      { type: 14, spacing: 1 },
      { type: 10, content: "<@#{from_id}> and <@#{to_id}> are officially married! Congratulations, chat!! #{EMOJI_STRINGS['neonsparkle']}\n\n*Both of you now get +#{MARRIAGE_DAILY_BONUS} bonus coins on your daily claims!*" }
    ]}]
  )
end

$bot.button(custom_id: /^marry_decline_/) do |event|
  parts = event.custom_id.split('_')
  from_id = parts[2].to_i
  to_id = parts[3].to_i
  proposal_id = "proposal_#{from_id}_#{to_id}"

  if event.user.id != to_id
    next event.respond(content: "#{EMOJI_STRINGS['x_']} This proposal isn't for you.", ephemeral: true)
  end

  ACTIVE_PROPOSALS.delete(proposal_id)

  event.update_message(
    content: '', flags: CV2_FLAG,
    components: [{ type: 17, accent_color: 0xFF0000, components: [
      { type: 10, content: "## 💔 Proposal Declined" },
      { type: 14, spacing: 1 },
      { type: 10, content: "<@#{to_id}> said no to <@#{from_id}>... *yikes*. That's tough, chat." }
    ]}]
  )
end
