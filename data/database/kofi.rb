# ==========================================
# MODULE: Database Ko-fi Integration
# DESCRIPTION: Ko-fi account linking and premium subscription management.
# ==========================================

module DatabaseKofi
  # --- ACCOUNT LINKING ---

  def link_kofi(user_id, email)
    @db.exec_params(
      "INSERT INTO kofi_links (user_id, kofi_email) VALUES ($1, $2)
       ON CONFLICT (user_id) DO UPDATE SET kofi_email = $2, linked_at = NOW()",
      [user_id, email.downcase.strip]
    )
  end

  def unlink_kofi(user_id)
    @db.exec_params("DELETE FROM kofi_links WHERE user_id = $1", [user_id])
  end

  def get_kofi_link(user_id)
    row = @db.exec_params("SELECT kofi_email FROM kofi_links WHERE user_id = $1", [user_id]).first
    row ? row['kofi_email'] : nil
  end

  def find_user_by_kofi_email(email)
    row = @db.exec_params("SELECT user_id FROM kofi_links WHERE kofi_email = $1", [email.downcase.strip]).first
    row ? row['user_id'].to_i : nil
  end

  # --- SUBSCRIPTION MANAGEMENT ---

  def activate_premium_sub(user_id, transaction_id, tier, duration_days)
    expires = Time.now + (duration_days * 86400)
    @db.exec_params(
      "INSERT INTO premium_subscriptions (user_id, kofi_transaction_id, tier, started_at, expires_at, active)
       VALUES ($1, $2, $3, NOW(), $4, 1)
       ON CONFLICT (user_id) DO UPDATE SET
         kofi_transaction_id = $2, tier = $3, expires_at = $4, active = 1",
      [user_id, transaction_id, tier, expires]
    )
  end

  def extend_premium_sub(user_id, transaction_id, duration_days)
    # If active and not expired, extend from current expiry. Otherwise start fresh from now.
    row = @db.exec_params(
      "SELECT expires_at, active FROM premium_subscriptions WHERE user_id = $1", [user_id]
    ).first

    if row && row['active'].to_i == 1 && Time.parse(row['expires_at']) > Time.now
      new_expiry = Time.parse(row['expires_at']) + (duration_days * 86400)
    else
      new_expiry = Time.now + (duration_days * 86400)
    end

    @db.exec_params(
      "INSERT INTO premium_subscriptions (user_id, kofi_transaction_id, tier, started_at, expires_at, active)
       VALUES ($1, $2, 'monthly', NOW(), $3, 1)
       ON CONFLICT (user_id) DO UPDATE SET
         kofi_transaction_id = $2, expires_at = $3, active = 1",
      [user_id, transaction_id, new_expiry]
    )
  end

  def deactivate_premium_sub(user_id)
    @db.exec_params(
      "UPDATE premium_subscriptions SET active = 0 WHERE user_id = $1", [user_id]
    )
  end

  def has_active_kofi_sub?(user_id)
    row = @db.exec_params(
      "SELECT active, expires_at FROM premium_subscriptions WHERE user_id = $1", [user_id]
    ).first
    return false unless row
    row['active'].to_i == 1 && Time.parse(row['expires_at']) > Time.now
  end

  def get_premium_sub(user_id)
    @db.exec_params(
      "SELECT * FROM premium_subscriptions WHERE user_id = $1", [user_id]
    ).first
  end

  def expire_lapsed_subs
    @db.exec("UPDATE premium_subscriptions SET active = 0 WHERE active = 1 AND expires_at < NOW()")
  end
end
