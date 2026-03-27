# ==========================================
# COMMAND: syncachievements (Developer Only)
# DESCRIPTION: Scans all users globally to retroactively grant missing achievements.
# CATEGORY: Developer / Maintenance
# ==========================================

# ------------------------------------------
# LOGIC: Global Achievement Sync Execution
# ------------------------------------------
def execute_global_sync(event)
  # 1. UI Feedback: Provide an immediate response to let the developer know it started
  if event.is_a?(Discordrb::Events::ApplicationCommandEvent)
    event.defer # Slash commands need more time for this heavy task
  else
    resp = send_cv2(event, [{ type: 17, accent_color: NEON_COLORS.sample, components: [
      { type: 10, content: "## ⏳ Syncing..." },
      { type: 14, spacing: 1 },
      { type: 10, content: "Starting global achievement sync... Blossom is checking everyone!" }
    ]}])
    @sync_channel_id = event.channel.id
    @sync_msg_id = JSON.parse(resp.body)['id'] rescue nil
  end

  # 2. Threading: Move the logic to a background thread to prevent the bot from freezing
  Thread.new do
    begin
      # 3. Data Gathering: Collect every unique User ID the bot can see across all servers
      all_user_ids = event.bot.servers.values.flat_map { |s| s.members.map(&:id) }.uniq
      total_users = all_user_ids.size

      total_unlocked = 0
      users_affected = 0
      batch_size = 25
      last_update = Time.now

      # Helper to build a progress update
      update_progress = proc do |processed, done = false|
        pct = total_users > 0 ? ((processed.to_f / total_users) * 100).round : 0
        bar_filled = pct / 5
        bar = ('▓' * bar_filled) + ('░' * (20 - bar_filled))

        if done
          status = "## #{EMOJI_STRINGS['checkmark']} Global Achievement Sync Complete\n\n" \
                   "Scanned **#{total_users}** users across **#{event.bot.servers.size}** servers.\n\n" \
                   "`#{bar}` **100%**\n\n" \
                   "#{EMOJI_STRINGS['crown']} **#{users_affected}** users received missing achievements.\n" \
                   "#{EMOJI_STRINGS['neonsparkle']} **#{total_unlocked}** total achievements retroactively unlocked!\n\n" \
                   "*(All coin rewards have been deposited automatically!)*#{mom_remark(event.user.id, 'dev')}"
          color = 0x00FF00
        else
          status = "## ⏳ Syncing Achievements...\n\n" \
                   "Scanning **#{total_users}** users — hang tight, mama's running diagnostics on the whole arcade.\n\n" \
                   "`#{bar}` **#{pct}%** (#{processed}/#{total_users})\n\n" \
                   "#{EMOJI_STRINGS['neonsparkle']} **#{total_unlocked}** unlocked so far for **#{users_affected}** users..."
          color = NEON_COLORS.sample
        end
        [status, color]
      end

      # 4. Initial progress message
      status, color = update_progress.call(0)
      if event.is_a?(Discordrb::Events::ApplicationCommandEvent)
        embed = Discordrb::Webhooks::Embed.new(title: nil, description: status, color: color)
        event.edit_response(embeds: [embed])
      elsif @sync_msg_id
        body = { content: '', flags: CV2_FLAG, components: [{ type: 17, accent_color: color, components: [
          { type: 10, content: status }
        ]}] }.to_json
        Discordrb::API.request(:channels_cid_messages_mid, @sync_channel_id, :patch,
          "#{Discordrb::API.api_base}/channels/#{@sync_channel_id}/messages/#{@sync_msg_id}",
          body, Authorization: $bot.token, content_type: :json)
      end

      # 5. Processing: Loop through each user with live progress updates
      all_user_ids.each_with_index do |uid, idx|
        count = sync_user_achievements(uid)
        if count > 0
          total_unlocked += count
          users_affected += 1
        end

        processed = idx + 1

        # Update progress every batch_size users or every 5 seconds
        if processed % batch_size == 0 || (Time.now - last_update) >= 5
          last_update = Time.now
          status, color = update_progress.call(processed)
          begin
            if event.is_a?(Discordrb::Events::ApplicationCommandEvent)
              embed = Discordrb::Webhooks::Embed.new(title: nil, description: status, color: color)
              event.edit_response(embeds: [embed])
            elsif @sync_msg_id
              body = { content: '', flags: CV2_FLAG, components: [{ type: 17, accent_color: color, components: [
                { type: 10, content: status }
              ]}] }.to_json
              Discordrb::API.request(:channels_cid_messages_mid, @sync_channel_id, :patch,
                "#{Discordrb::API.api_base}/channels/#{@sync_channel_id}/messages/#{@sync_msg_id}",
                body, Authorization: $bot.token, content_type: :json)
            end
          rescue => e
            puts "[SYNC PROGRESS] Edit failed: #{e.message}"
          end
        end

        sleep 0.05 # Lighter rate limit — 50ms instead of 100ms
      end

      # 6. Final completion update
      status, color = update_progress.call(total_users, true)
      if event.is_a?(Discordrb::Events::ApplicationCommandEvent)
        embed = Discordrb::Webhooks::Embed.new(title: nil, description: status, color: color)
        event.edit_response(embeds: [embed]) rescue nil
      elsif @sync_msg_id
        body = { content: '', flags: CV2_FLAG, components: [{ type: 17, accent_color: color, components: [
          { type: 10, content: status }
        ]}] }.to_json
        Discordrb::API.request(:channels_cid_messages_mid, @sync_channel_id, :patch,
          "#{Discordrb::API.api_base}/channels/#{@sync_channel_id}/messages/#{@sync_msg_id}",
          body, Authorization: $bot.token, content_type: :json)
      end

    rescue => e
      puts "❌ Global Sync Error: #{e.message}"
      puts e.backtrace.first(5).join("\n")
    end
  end
end

# ------------------------------------------
# TRIGGER: Prefix Command (b!syncachievements)
# ------------------------------------------
$bot.command(:syncachievements, aliases: [:sync],
  description: 'Retroactively grant achievements to everyone (Dev Only)', 
  category: 'Developer'
) do |event|
  # Security: Only the developer can trigger a global database scan
  return unless DEV_IDS.include?(event.user.id)
  
  execute_global_sync(event)
  nil # Suppress default return
end