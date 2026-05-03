# ==========================================
# MODULE: DatabaseKofi
# DESCRIPTION: Idempotent Ko-fi webhook deduplication rows.
# ==========================================

module DatabaseKofi
  # Stores one row per webhook `message_identifier` Ko-fi emits.
  # Returns:
  #   :reject — missing identifier
  #   :duplicate — already handled
  #   :ok — newly recorded
  def record_kofi_webhook_processed(event_id:, discord_user_id: nil)
    eid = event_id.to_s.strip
    return :reject if eid.empty?

    did = discord_user_id
    row = @db.exec_params(
      <<~SQL,
        INSERT INTO kofi_webhooks_processed (event_id, discord_user_id)
        VALUES ($1, $2)
        ON CONFLICT (event_id) DO NOTHING
        RETURNING event_id
      SQL
      [eid, did]
    ).first

    row ? :ok : :duplicate
  rescue PG::Error => err
    puts "[KOFI DB ERROR] #{err.class}: #{err.message}"
    :reject
  end
end
