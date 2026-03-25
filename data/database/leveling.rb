    # --- LEADERBOARD: Global Server Leaderboard ---
    def get_global_server_leaderboard(limit = 10)
      @db.exec_params("SELECT server_id, server_name, xp, level FROM community_levels ORDER BY xp DESC, level DESC LIMIT $1", [limit]).to_a
    end

    public :get_global_server_leaderboard
  # --- LEADERBOARD: Top Users by XP/Level ---
  def get_top_users(server_id, limit = 50)
    @db.exec_params("SELECT user_id, xp, level FROM server_xp WHERE server_id = $1 ORDER BY level DESC, xp DESC LIMIT $2", [server_id, limit]).to_a
  end

  public :get_top_users
module DatabaseLeveling
    # --- COMMUNITY LEVEL-UP ANNOUNCEMENT TOGGLE ---
    def toggle_community_levelup(server_id)
      # Add the column if it doesn't exist (migration safety)
      begin
        @db.exec("ALTER TABLE community_levels ADD COLUMN IF NOT EXISTS announce_enabled INTEGER DEFAULT 0")
      rescue PG::Error
      end

      # Ensure the row exists
      @db.exec_params("INSERT INTO community_levels (server_id) VALUES ($1) ON CONFLICT (server_id) DO NOTHING", [server_id])

      # Flip the value
      @db.exec_params("UPDATE community_levels SET announce_enabled = 1 - COALESCE(announce_enabled, 0) WHERE server_id = $1", [server_id])

      # Return the new value
      row = @db.exec_params("SELECT announce_enabled FROM community_levels WHERE server_id = $1", [server_id]).first
      row && row['announce_enabled'].to_i == 1
    end

    public :toggle_community_levelup
  # --- USER LEVELING ---
  def get_user_xp(sid, uid)
    row = @db.exec_params("SELECT xp, level, last_xp_at FROM server_xp WHERE server_id = $1 AND user_id = $2", [sid, uid]).first
    if row
      { 'xp' => row['xp'].to_i, 'level' => row['level'].to_i, 'last_xp_at' => (row['last_xp_at'] ? Time.parse(row['last_xp_at']) : nil) }
    else
      { 'xp' => 0, 'level' => 1, 'last_xp_at' => nil }
    end
  end

  def update_user_xp(sid, uid, xp, level, last_xp_at)
    time_str = last_xp_at ? last_xp_at.iso8601 : nil
    @db.exec_params("INSERT INTO server_xp (server_id, user_id, xp, level, last_xp_at) VALUES ($1, $2, $3, $4, $5) ON CONFLICT (server_id, user_id) DO UPDATE SET xp = $6, level = $7, last_xp_at = $8", [sid, uid, xp, level, time_str, xp, level, time_str])
  end

  # --- COMMUNITY (SERVER) LEVELING ---
  def get_community_level(server_id)
    result = @db.exec_params("SELECT xp, level FROM community_levels WHERE server_id = $1", [server_id]).to_a
    result.empty? ? { 'xp' => 0, 'level' => 1 } : result[0]
  end

  def update_community_level(server_id, server_name, new_xp, new_level)
    @db.exec_params("INSERT INTO community_levels (server_id, server_name, xp, level) VALUES ($1, $2, $3, $4) ON CONFLICT (server_id) DO UPDATE SET server_name = EXCLUDED.server_name, xp = EXCLUDED.xp, level = EXCLUDED.level", [server_id, server_name, new_xp, new_level])
  end
end