# ==========================================
# MODULE: DatabaseVotes (Top.gg)
# DESCRIPTION: Vote idempotency, streak Prisma rewards, DM reminder flags.
# ==========================================

module DatabaseVotes
  TOPGG_STREAK_CAP = 10
  TOPGG_STREAK_GAP_SECONDS = 28 * 3600
  TOPGG_BASE_PRISMA = 5

  def topgg_vote_state(uid)
    row = @db.exec_params(
      'SELECT user_id, last_vote_at, vote_streak, reminder_dm, next_vote_after, last_reminder_at FROM topgg_vote_state WHERE user_id = $1',
      [uid.to_i]
    ).first
    return default_topgg_vote_state unless row

    {
      last_vote_at: row['last_vote_at'] ? Time.parse(row['last_vote_at'].to_s) : nil,
      vote_streak: row['vote_streak'].to_i,
      reminder_dm: row['reminder_dm'].to_i == 1,
      next_vote_after: row['next_vote_after'] ? Time.parse(row['next_vote_after'].to_s) : nil,
      last_reminder_at: row['last_reminder_at'] ? Time.parse(row['last_reminder_at'].to_s) : nil
    }
  end

  def default_topgg_vote_state
    {
      last_vote_at: nil,
      vote_streak: 0,
      reminder_dm: false,
      next_vote_after: nil,
      last_reminder_at: nil
    }
  end

  def toggle_topgg_vote_reminder(uid)
    u = uid.to_i
    @db.exec_params(
      <<~SQL,
        INSERT INTO topgg_vote_state (user_id, reminder_dm)
        VALUES ($1, 1)
        ON CONFLICT (user_id) DO UPDATE SET reminder_dm = 1 - COALESCE(topgg_vote_state.reminder_dm, 0)
      SQL
      [u]
    )
    row = @db.exec_params('SELECT reminder_dm FROM topgg_vote_state WHERE user_id = $1', [u]).first
    row && row['reminder_dm'].to_i == 1
  end

  # Atomically claim a Top.gg vote webhook: idempotent. Blacklisted users record vote_id but get no Prisma.
  # Returns Hash with :status (:ok, :duplicate, :skipped_blacklist), :prisma, :streak, :streak_used
  def apply_topgg_vote(vote_id:, discord_uid:, weight:, next_vote_after:, now: Time.now)
    uid = discord_uid.to_i
    return { status: :reject, prisma: 0, streak: 0, streak_used: 0 } if uid.zero?

    blacklisted = topgg_user_blacklisted?(uid)
    w = [weight.to_i, 1].max
    prisma_total = 0
    new_streak = 0
    streak_for_reward = 0
    status = :ok

    @db.transaction do |conn|
      ins = conn.exec_params(
        'INSERT INTO topgg_votes_processed (vote_id, user_id) VALUES ($1, $2) ON CONFLICT (vote_id) DO NOTHING RETURNING vote_id',
        [vote_id.to_s, uid]
      )
      if ins.ntuples.zero?
        status = :duplicate
      elsif blacklisted
        status = :skipped_blacklist
      else
        row = conn.exec_params(
          'SELECT last_vote_at, vote_streak FROM topgg_vote_state WHERE user_id = $1 FOR UPDATE',
          [uid]
        ).first

        last_at = row && row['last_vote_at'] ? Time.parse(row['last_vote_at'].to_s) : nil
        s = row ? row['vote_streak'].to_i : 0

        if last_at.nil? || (now - last_at) > TOPGG_STREAK_GAP_SECONDS
          streak_for_reward = 0
          new_streak = 0
        else
          new_streak = [s + 1, TOPGG_STREAK_CAP].min
          streak_for_reward = new_streak
        end

        prisma_unit = TOPGG_BASE_PRISMA + streak_for_reward
        prisma_total = prisma_unit * w

        conn.exec_params(
          <<~SQL,
            INSERT INTO topgg_vote_state (user_id, last_vote_at, vote_streak, next_vote_after)
            VALUES ($1, $2, $3, $4)
            ON CONFLICT (user_id) DO UPDATE SET
              last_vote_at = EXCLUDED.last_vote_at,
              vote_streak = EXCLUDED.vote_streak,
              next_vote_after = EXCLUDED.next_vote_after
          SQL
          [uid, now.iso8601, new_streak, next_vote_after&.iso8601]
        )

        if prisma_total.positive?
          conn.exec_params(
            'INSERT INTO user_prisma (user_id, balance) VALUES ($1, $2) ON CONFLICT (user_id) DO UPDATE SET balance = user_prisma.balance + $3',
            [uid, prisma_total, prisma_total]
          )
        end
      end
    end

    { status: status, prisma: prisma_total, streak: new_streak, streak_used: streak_for_reward }
  end

  def topgg_user_blacklisted?(uid)
    @db.exec_params('SELECT 1 FROM blacklist WHERE user_id = $1 LIMIT 1', [uid.to_i]).any?
  end

  def topgg_users_ready_for_reminder(now_iso)
    @db.exec_params(
      <<~SQL,
        SELECT user_id, next_vote_after
        FROM topgg_vote_state
        WHERE COALESCE(reminder_dm, 0) = 1
          AND next_vote_after IS NOT NULL
          AND next_vote_after <= $1::timestamptz
          AND (
            last_reminder_at IS NULL
            OR last_reminder_at < topgg_vote_state.next_vote_after
          )
      SQL
      [now_iso]
    ).to_a
  end

  def mark_topgg_vote_reminder_sent(uid, at = Time.now)
    @db.exec_params(
      'UPDATE topgg_vote_state SET last_reminder_at = $2 WHERE user_id = $1',
      [uid.to_i, at.iso8601]
    )
  end
end
