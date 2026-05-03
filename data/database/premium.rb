# ==========================================
# MODULE: DatabasePremium
# DESCRIPTION: Subscriber chest, event VIP, summon discounts, streak insurance, pity head-start.
# ==========================================

module DatabasePremium
  def premium_iso_week_key
    Time.now.utc.strftime('%G-W%V')
  end

  def premium_month_ym
    Time.now.utc.strftime('%Y-%m')
  end

  def ensure_premium_extras_row(uid)
    @db.exec_params(
      'INSERT INTO premium_extras (user_id) VALUES ($1) ON CONFLICT (user_id) DO NOTHING',
      [uid]
    )
  end

  def premium_monthly_chest_claimed?(uid, ym)
    row = @db.exec_params('SELECT monthly_chest_ym FROM premium_extras WHERE user_id = $1', [uid]).first
    row && row['monthly_chest_ym'] == ym
  end

  def mark_monthly_chest_claimed(uid, ym)
    ensure_premium_extras_row(uid)
    @db.exec_params(
      'INSERT INTO premium_extras (user_id, monthly_chest_ym) VALUES ($1, $2) ON CONFLICT (user_id) DO UPDATE SET monthly_chest_ym = $2',
      [uid, ym]
    )
  end

  def can_use_streak_insurance?(uid)
    row = @db.exec_params('SELECT streak_insurance_iso_week FROM premium_extras WHERE user_id = $1', [uid]).first
    return true unless row
    row['streak_insurance_iso_week'].to_s != premium_iso_week_key
  end

  def consume_streak_insurance(uid)
    ensure_premium_extras_row(uid)
    wk = premium_iso_week_key
    @db.exec_params(
      'INSERT INTO premium_extras (user_id, streak_insurance_iso_week) VALUES ($1, $2) ON CONFLICT (user_id) DO UPDATE SET streak_insurance_iso_week = $2',
      [uid, wk]
    )
  end

  def event_vip_claimed_today?(uid, date)
    row = @db.exec_params('SELECT event_vip_claim_date FROM premium_extras WHERE user_id = $1', [uid]).first
    row && row['event_vip_claim_date'].to_s == date.to_s
  end

  def mark_event_vip_claimed(uid, date)
    ensure_premium_extras_row(uid)
    @db.exec_params(
      "INSERT INTO premium_extras (user_id, event_vip_claim_date) VALUES ($1, $2) ON CONFLICT (user_id) DO UPDATE SET event_vip_claim_date = $2",
      [uid, date]
    )
  end

  def premium_summon_discount_remaining(uid)
    ensure_premium_extras_row(uid)
    wk = premium_iso_week_key
    row = @db.exec_params(
      'SELECT summon_disc_iso_week, summon_disc_uses FROM premium_extras WHERE user_id = $1',
      [uid]
    ).first
    uses = 0
    if row && row['summon_disc_iso_week'].to_s == wk
      uses = row['summon_disc_uses'].to_i
    end
    [WEEKLY_SUMMON_DISCOUNT_USES - uses, 0].max
  end

  def consume_premium_summon_discount(uid)
    ensure_premium_extras_row(uid)
    wk = premium_iso_week_key
    row = @db.exec_params(
      'SELECT summon_disc_iso_week, summon_disc_uses FROM premium_extras WHERE user_id = $1',
      [uid]
    ).first
    uses = 0
    if row && row['summon_disc_iso_week'].to_s == wk
      uses = row['summon_disc_uses'].to_i
    end
    @db.exec_params(
      'INSERT INTO premium_extras (user_id, summon_disc_iso_week, summon_disc_uses) VALUES ($1, $2, $3) ON CONFLICT (user_id) DO UPDATE SET summon_disc_iso_week = $2, summon_disc_uses = $3',
      [uid, wk, uses + 1]
    )
  end

  def apply_weekly_premium_pity_headstart(uid)
    ensure_premium_extras_row(uid)
    wk = premium_iso_week_key
    res = @db.exec_params(
      'UPDATE premium_extras SET pity_headstart_iso_week = $2 WHERE user_id = $1 AND (pity_headstart_iso_week IS DISTINCT FROM $2) RETURNING user_id',
      [uid, wk]
    )
    return if res.ntuples.zero?

    @db.exec_params(
      'UPDATE global_users SET pity_counter = LEAST(pity_counter + $2, $3) WHERE user_id = $1',
      [uid, WEEKLY_PITY_HEADSTART_BONUS, PITY_THRESHOLD - 1]
    )
  end

  def get_leaderboard_epithet(uid)
    row = @db.exec_params('SELECT leaderboard_epithet FROM global_users WHERE user_id = $1', [uid]).first
    row && row['leaderboard_epithet'].to_s.strip != '' ? row['leaderboard_epithet'].to_s : nil
  end

  def set_leaderboard_epithet(uid, text)
    v = text.nil? || text.to_s.strip.empty? ? nil : text.to_s.strip[0, 24]
    @db.exec_params(
      'INSERT INTO global_users (user_id, leaderboard_epithet) VALUES ($1, $2) ON CONFLICT (user_id) DO UPDATE SET leaderboard_epithet = $2',
      [uid, v]
    )
    CACHE.invalidate(:profile, uid)
  end

  def get_profile_tagline(uid)
    row = @db.exec_params('SELECT profile_tagline FROM global_users WHERE user_id = $1', [uid]).first
    row && row['profile_tagline'].to_s.strip != '' ? row['profile_tagline'].to_s : nil
  end

  def set_profile_tagline(uid, text)
    v = text.nil? || text.to_s.strip.empty? ? nil : text.to_s.strip[0, 120]
    @db.exec_params(
      'INSERT INTO global_users (user_id, profile_tagline) VALUES ($1, $2) ON CONFLICT (user_id) DO UPDATE SET profile_tagline = $2',
      [uid, v]
    )
    CACHE.invalidate(:profile, uid)
  end
end
