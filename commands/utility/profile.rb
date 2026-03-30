# ==========================================
# COMMAND: profile
# DESCRIPTION: Premium profile customization — color, bio, favorites.
# CATEGORY: Utility
# ==========================================

def format_fav_line(name)
  result = find_character_in_pools(name)
  return nil unless result
  emoji = case result[:rarity]
          when 'goddess'   then EMOJI_STRINGS['goddess']
          when 'legendary' then EMOJI_STRINGS['legendary']
          when 'rare'      then EMOJI_STRINGS['rare']
          else EMOJI_STRINGS['common']
          end
  "#{emoji} #{name}"
end

def execute_profile(event, action, args)
  uid = event.user.id
  is_sub = is_premium?(event.bot, uid)

  unless is_sub
    return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['prisma']} Premium Only" },
      { type: 14, spacing: 1 },
      { type: 10, content: "Profile customization is a **Blossom Premium** perk! Subscribe to flex on the peasants." }
    ]}])
  end

  profile = DB.get_profile(uid)

  # No args = show current profile settings
  if action.nil?
    color_display = profile['color'] ? "`##{profile['color']}`" : "*Not set (random neon)*"
    bio_display = profile['bio'] && !profile['bio'].empty? ? profile['bio'] : "*Not set*"
    favs = profile['favorites']
    fav_display = favs.empty? ? "*None set*" : favs.each_with_index.map { |f, i| "**#{i + 1}.** #{format_fav_line(f) || f}" }.join("\n")

    return send_cv2(event, [{ type: 17, accent_color: profile['color'] ? profile['color'].to_i(16) : NEON_COLORS.sample, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['neonsparkle']} Profile Settings" },
      { type: 14, spacing: 1 },
      { type: 10, content: "🎨 **Color:** #{color_display}" },
      { type: 10, content: "📝 **Bio:** #{bio_display}" },
      { type: 10, content: "#{EMOJI_STRINGS['hearts']} **Favorites:**\n#{fav_display}" },
      { type: 14, spacing: 1 },
      { type: 10, content: "-# `#{PREFIX}profile color <#hex>` · `#{PREFIX}profile bio <text>` · `#{PREFIX}profile fav <slot> <name>`\n-# `#{PREFIX}profile reset` to clear everything" }
    ]}])
  end

  case action.downcase
  when 'color'
    hex = args.first&.delete('#')&.strip
    unless hex && hex.match?(/\A[0-9a-fA-F]{6}\z/)
      return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
        { type: 10, content: "## #{EMOJI_STRINGS['x_']} Invalid Color" },
        { type: 14, spacing: 1 },
        { type: 10, content: "I need a valid 6-digit hex code, chat. Like `#FF00AA` or `#7B2FBE`." }
      ]}])
    end

    DB.set_profile_color(uid, hex.upcase)
    send_cv2(event, [{ type: 17, accent_color: hex.to_i(16), components: [
      { type: 10, content: "## 🎨 Color Updated!" },
      { type: 14, spacing: 1 },
      { type: 10, content: "Your profile color is now `##{hex.upcase}`. Looking fresh~" }
    ]}])

  when 'bio'
    text = args.join(' ').strip
    if text.empty?
      return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
        { type: 10, content: "## #{EMOJI_STRINGS['x_']} Missing Bio" },
        { type: 14, spacing: 1 },
        { type: 10, content: "You gotta actually write something. `#{PREFIX}profile bio <your bio here>`" }
      ]}])
    end

    if text.length > 100
      return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
        { type: 10, content: "## #{EMOJI_STRINGS['x_']} Too Long" },
        { type: 14, spacing: 1 },
        { type: 10, content: "Max 100 characters, bestie. You wrote #{text.length}. Less is more." }
      ]}])
    end

    DB.set_profile_bio(uid, text)
    send_cv2(event, [{ type: 17, accent_color: 0x00FF00, components: [
      { type: 10, content: "## 📝 Bio Updated!" },
      { type: 14, spacing: 1 },
      { type: 10, content: "Your bio is now: *\"#{text}\"*" }
    ]}])

  when 'fav'
    slot = args[0]&.to_i
    name = args[1..].join(' ').strip if args.length > 1

    unless slot && (1..3).include?(slot) && name && !name.empty?
      return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
        { type: 10, content: "## #{EMOJI_STRINGS['x_']} Usage" },
        { type: 14, spacing: 1 },
        { type: 10, content: "`#{PREFIX}profile fav <1/2/3> <character name>`\nSlot 1 is available to all premium users. Slots 2 and 3 let you flex harder." }
      ]}])
    end

    # Verify they own the card
    collection = DB.get_collection(uid)
    owned = collection.keys.find { |k| k.downcase == name.downcase }
    unless owned
      return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
        { type: 10, content: "## #{EMOJI_STRINGS['x_']} Not Found" },
        { type: 14, spacing: 1 },
        { type: 10, content: "You don't own a card called **#{name}**. Check your collection!" }
      ]}])
    end

    DB.set_favorite_card_slot(uid, slot, owned)
    fav_display = format_fav_line(owned) || owned
    send_cv2(event, [{ type: 17, accent_color: 0x00FF00, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['hearts']} Favorite Set!" },
      { type: 14, spacing: 1 },
      { type: 10, content: "Slot **##{slot}** is now #{fav_display}. Looking good on your profile~" }
    ]}])

  when 'unfav'
    slot = args[0]&.to_i
    unless slot && (1..3).include?(slot)
      return send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
        { type: 10, content: "## #{EMOJI_STRINGS['x_']} Usage" },
        { type: 14, spacing: 1 },
        { type: 10, content: "`#{PREFIX}profile unfav <1/2/3>`" }
      ]}])
    end

    DB.clear_favorite_slot(uid, slot)
    send_cv2(event, [{ type: 17, accent_color: 0x00FF00, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['checkmark']} Favorite Cleared" },
      { type: 14, spacing: 1 },
      { type: 10, content: "Slot **##{slot}** is now empty." }
    ]}])

  when 'reset'
    DB.set_profile_color(uid, nil)
    DB.set_profile_bio(uid, nil)
    (1..3).each { |s| DB.clear_favorite_slot(uid, s) }
    send_cv2(event, [{ type: 17, accent_color: 0x00FF00, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['checkmark']} Profile Reset" },
      { type: 14, spacing: 1 },
      { type: 10, content: "All profile customizations cleared. Back to default neon vibes." }
    ]}])

  else
    send_cv2(event, [{ type: 17, accent_color: 0xFF0000, components: [
      { type: 10, content: "## #{EMOJI_STRINGS['confused']} Unknown Option" },
      { type: 14, spacing: 1 },
      { type: 10, content: "Try `color`, `bio`, `fav`, `unfav`, or `reset`.\n`#{PREFIX}profile` with no args to see your current settings." }
    ]}])
  end
end

# ------------------------------------------
# TRIGGERS: Prefix & Slash Support
# ------------------------------------------
$bot.command(:profile,
  description: 'Customize your premium profile!',
  category: 'Utility'
) do |event, action, *args|
  execute_profile(event, action, args)
  nil
end

$bot.application_command(:profile) do |event|
  action = event.options['action']
  value = event.options['value'] || ''
  execute_profile(event, action, value.split(' '))
end
