# ==========================================
# COMMAND: link
# DESCRIPTION: Link your Ko-fi email to unlock Premium perks.
# CATEGORY: Utility
# ==========================================

def execute_link(event, action, email_str)
  uid = event.user.id

  # Default to 'view' if no action
  action = (action || 'view').downcase

  case action
  when 'view', 'status'
    linked_email = DB.get_kofi_link(uid)
    if linked_email
      # Mask the email for privacy (show first 3 chars + domain)
      parts = linked_email.split('@')
      masked = parts[0].length > 3 ? "#{parts[0][0..2]}***@#{parts[1]}" : "***@#{parts[1]}"

      send_cv2(event, [{ type: 17, accent_color: NEON_COLORS.sample, components: [
        { type: 10, content: "## #{EMOJI_STRINGS['checkmark']} Ko-fi Linked" },
        { type: 14, spacing: 1 },
        { type: 10, content: "Your account is linked to **#{masked}**.\nWhen you subscribe on Ko-fi, premium activates automatically!" },
        { type: 14, spacing: 1 },
        { type: 10, content: "-# To change: `#{PREFIX}link set <new-email>`\n-# To remove: `#{PREFIX}link remove`" }
      ]}])
    else
      send_cv2(event, [{ type: 17, accent_color: 0xFF6B6B, components: [
        { type: 10, content: "## #{EMOJI_STRINGS['info']} Ko-fi Not Linked" },
        { type: 14, spacing: 1 },
        { type: 10, content: "Link your Ko-fi email so premium kicks in automatically when you subscribe!" },
        { type: 14, spacing: 1 },
        { type: 10, content: "`#{PREFIX}link set your@email.com`" },
        { type: 14, spacing: 1 },
        { type: 10, content: "-# Use the same email you use on Ko-fi. It's stored securely and only used for payment matching." }
      ]}])
    end

  when 'set'
    unless email_str && email_str.match?(/\A[^@\s]+@[^@\s]+\.[^@\s]+\z/)
      return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
        { type: 10, content: "## #{EMOJI_STRINGS['x_']} Invalid Email" },
        { type: 14, spacing: 1 },
        { type: 10, content: "That doesn't look like a real email, bestie.\n`#{PREFIX}link set your@email.com`" }
      ]}])
    end

    DB.link_kofi(uid, email_str)

    send_cv2(event, [{ type: 17, accent_color: 0x00FF00, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['checkmark']} Ko-fi Linked!" },
      { type: 14, spacing: 1 },
      { type: 10, content: "Your Ko-fi email has been linked! #{EMOJI_STRINGS['neonsparkle']}\nNow when you subscribe on Ko-fi, your premium perks activate automatically." },
      { type: 14, spacing: 1 },
      { type: 10, content: "-# Make sure this matches the email on your Ko-fi account!" }
    ]}])

  when 'remove', 'unlink'
    DB.unlink_kofi(uid)

    send_cv2(event, [{ type: 17, accent_color: 0xFF6B6B, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['checkmark']} Ko-fi Unlinked" },
      { type: 14, spacing: 1 },
      { type: 10, content: "Your Ko-fi email has been removed.\nYou can re-link anytime with `#{PREFIX}link set your@email.com`." }
    ]}])

  else
    send_cv2(event, [{ type: 17, accent_color: NEON_COLORS.sample, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['info']} Link Commands" },
      { type: 14, spacing: 1 },
      { type: 10, content: "`#{PREFIX}link` — View your linked Ko-fi email\n`#{PREFIX}link set <email>` — Link your Ko-fi email\n`#{PREFIX}link remove` — Unlink your email" }
    ]}])
  end
end

# ------------------------------------------
# TRIGGERS
# ------------------------------------------
$bot.command(:link, aliases: [:kofi],
  description: 'Link your Ko-fi email for auto-premium!',
  category: 'Utility'
) do |event, action, email_str|
  execute_link(event, action, email_str)
  nil
end

$bot.application_command(:link) do |event|
  execute_link(event, event.options['action'], event.options['email'])
end
