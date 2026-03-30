# ==========================================
# MODULE: Database Gacha
# DESCRIPTION: Handles character collections, trading, and ascension.
# ==========================================

module DatabaseGacha
  def get_collection(uid)
    rows = @db.exec_params("SELECT character_name, rarity, count, ascended FROM collections WHERE user_id = $1", [uid])
    col = {}
    rows.each do |r|
      col[r['character_name']] = { 'rarity' => r['rarity'], 'count' => r['count'].to_i, 'ascended' => r['ascended'].to_i }
    end
    col
  end

  def add_character(uid, name, rarity, amount = 1)
    @db.exec_params("INSERT INTO collections (user_id, character_name, rarity, count, ascended) VALUES ($1, $2, $3, $4, 0) ON CONFLICT (user_id, character_name) DO UPDATE SET count = collections.count + $5", [uid, name, rarity, amount, amount])
  end

  def give_card(from_uid, to_uid, char_name, rarity)
    @db.exec_params("INSERT INTO global_users (user_id, coins) VALUES ($1, 0) ON CONFLICT DO NOTHING", [to_uid])
    @db.exec_params("UPDATE collections SET count = count - 1 WHERE user_id = $1 AND character_name = $2", [from_uid, char_name])
    @db.exec_params("INSERT INTO collections (user_id, character_name, rarity, count, ascended) VALUES ($1, $2, $3, 1, 0) ON CONFLICT (user_id, character_name) DO UPDATE SET count = collections.count + 1", [to_uid, char_name, rarity])
  end

  def ascend_character(uid, name)
    @db.exec_params("UPDATE collections SET count = count - 5, ascended = ascended + 1 WHERE user_id = $1 AND character_name = $2", [uid, name])
  end

  def remove_character(uid, name, amount = 1)
    @db.exec_params("UPDATE collections SET count = count - $3 WHERE user_id = $1 AND character_name = $2 AND count >= $3", [uid, name, amount])
    @db.exec_params("DELETE FROM collections WHERE user_id = $1 AND character_name = $2 AND count <= 0", [uid, name])
  end

  def set_card_count(uid, name, count)
    @db.exec_params("UPDATE collections SET count = $3 WHERE user_id = $1 AND character_name = $2", [uid, name, count])
  end

  def get_favorite_card(uid)
    row = @db.exec_params("SELECT favorite_card FROM global_users WHERE user_id = $1", [uid]).first
    row ? row['favorite_card'] : nil
  end

  def set_favorite_card(uid, name)
    @db.exec_params("INSERT INTO global_users (user_id, favorite_card) VALUES ($1, $2) ON CONFLICT (user_id) DO UPDATE SET favorite_card = $2", [uid, name])
  end

  def get_pity(uid)
    row = @db.exec_params("SELECT pity_counter FROM global_users WHERE user_id = $1", [uid]).first
    row ? row['pity_counter'].to_i : 0
  end

  def increment_pity(uid)
    @db.exec_params("UPDATE global_users SET pity_counter = pity_counter + 1 WHERE user_id = $1", [uid])
  end

  def reset_pity(uid)
    @db.exec_params("UPDATE global_users SET pity_counter = 0 WHERE user_id = $1", [uid])
  end

  # --- PREMIUM PROFILE ---
  def get_profile(uid)
    row = @db.exec_params("SELECT profile_color, bio, favorite_card, favorite_card_2, favorite_card_3 FROM global_users WHERE user_id = $1", [uid]).first
    if row
      {
        'color' => row['profile_color'],
        'bio' => row['bio'],
        'favorites' => [row['favorite_card'], row['favorite_card_2'], row['favorite_card_3']].compact
      }
    else
      { 'color' => nil, 'bio' => nil, 'favorites' => [] }
    end
  end

  def set_profile_color(uid, hex)
    @db.exec_params("INSERT INTO global_users (user_id, profile_color) VALUES ($1, $2) ON CONFLICT (user_id) DO UPDATE SET profile_color = $2", [uid, hex])
  end

  def set_profile_bio(uid, text)
    @db.exec_params("INSERT INTO global_users (user_id, bio) VALUES ($1, $2) ON CONFLICT (user_id) DO UPDATE SET bio = $2", [uid, text])
  end

  def set_favorite_card_slot(uid, slot, name)
    col = case slot
          when 1 then 'favorite_card'
          when 2 then 'favorite_card_2'
          when 3 then 'favorite_card_3'
          end
    @db.exec_params("INSERT INTO global_users (user_id, #{col}) VALUES ($1, $2) ON CONFLICT (user_id) DO UPDATE SET #{col} = $2", [uid, name])
  end

  def clear_favorite_slot(uid, slot)
    set_favorite_card_slot(uid, slot, nil)
  end
end
