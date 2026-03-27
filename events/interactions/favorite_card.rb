# ==========================================
# EVENT: Favorite Card Button
# DESCRIPTION: Handles the premium-only "Set as Favorite" button
# from the /view command. Saves a user's favorite card to display
# on their profile.
# ==========================================

$bot.button(custom_id: /^fav_card_/) do |event|
  parts = event.custom_id.split('_', 4)
  owner_id = parts[2]
  char_name = parts[3]

  # Only the card owner can favorite it
  if event.user.id.to_s != owner_id
    event.respond(content: "#{EMOJI_STRINGS['x_']} *That's not your card to favorite, chat.*", ephemeral: true)
    next
  end

  uid = event.user.id

  # Double-check premium status
  unless is_premium?(event.bot, uid)
    event.respond(content: "#{EMOJI_STRINGS['prisma']} *Favoriting cards is a Premium perk! Subscribe to flex your fave on your profile.*", ephemeral: true)
    next
  end

  # Verify they still own the card
  collection = DB.get_collection(uid)
  owned = collection.keys.find { |k| k == char_name }
  unless owned && (collection[owned]['count'] > 0 || collection[owned]['ascended'].to_i > 0)
    event.respond(content: "#{EMOJI_STRINGS['confused']} *You don't own that card anymore... awkward.*", ephemeral: true)
    next
  end

  # Set the favorite
  DB.set_favorite_card(uid, char_name)

  # Update the button to show it's favorited
  result = find_character_in_pools(char_name)
  rarity = result[:rarity]
  emoji = case rarity
          when 'goddess'   then EMOJI_STRINGS['goddess']
          when 'legendary' then EMOJI_STRINGS['legendary']
          when 'rare'      then EMOJI_STRINGS['rare']
          else EMOJI_STRINGS['common']
          end

  event.respond(content: "#{EMOJI_STRINGS['hearts']} **#{char_name}** is now your favorite! They'll show up on your profile. #{emoji}", ephemeral: true)
end
