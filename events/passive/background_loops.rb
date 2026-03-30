# ==========================================
# EVENT: Background Economy Loops
# DESCRIPTION: Houses the threads for hourly lotteries and 
# daily reminders. Wrapped in bot.ready so they don't crash on boot.
# ==========================================

$bot.ready do |event|
  
  # --- GLOBAL HOURLY LOTTERY DRAW ---
  Thread.new do
    loop do
      now = Time.now.to_i
      # Calculate exact seconds until the next top-of-the-hour
      sleep_time = 3600 - (now % 3600) 
      sleep(sleep_time)

      entries = DB.get_lottery_entries
      next if entries.nil? || entries.empty?
      
      DB.clear_lottery # Wipe it for the next hour

      begin
        winner_id = entries.sample
        jackpot = 100 + (entries.size * 100) # Base 100 + 100 per entry
        
        DB.add_coins(winner_id, jackpot)
        check_achievement(nil, winner_id, 'lottery_win', silent: true)

        winner_user = event.bot.user(winner_id)
        if winner_user
          begin
            winner_user.pm("#{EMOJI_STRINGS['neonsparkle']} **NO WAY — JACKPOT!** You just pulled **#{jackpot}** #{EMOJI_STRINGS['s_coin']} from the Hourly Lottery! Lucky you~ 🌸")
          rescue
            # Ignore if their DMs are closed
          end
        end
      rescue => e
        puts "[LOTTERY ERROR] #{e.message}"
      end
    end
  end

  # --- DAILY REMINDER PING ---
  Thread.new do
    loop do
      sleep(60) # Check the database once every minute
      
      begin
        pending_reminders = DB.get_pending_daily_reminders
        
        pending_reminders.each do |row|
          uid = row['user_id'].to_i
          chan_id = row['reminder_channel'].to_i

          # Premium gate — if they lapsed, silently disable their reminder
          unless is_premium?(event.bot, uid)
            DB.toggle_daily_reminder(uid, nil)
            next
          end

          channel = event.bot.channel(chan_id)
          if channel
            begin
              channel.send_message("🔔 <@#{uid}>, your `#{PREFIX}daily` is up! Don't break the streak or I WILL judge you. 🌸")
            rescue
              # Ignore if bot lacks permission to type in that channel
            end
          end
          DB.mark_reminder_sent(uid)
        end
      rescue => e
        puts "[REMINDER ERROR] #{e.message}"
      end
    end
  end

  # --- DAILY BIRTHDAY CHECK ---
  Thread.new do
    last_checked_date = nil
    loop do
      sleep(60)
      today = Time.now.strftime('%Y-%m-%d')
      next if today == last_checked_date

      last_checked_date = today
      begin
        birthday_uids = DB.get_todays_birthdays
        birthday_uids.each do |uid|
          DB.add_coins(uid, BIRTHDAY_REWARD)
          user = event.bot.user(uid)
          next unless user

          # Premium DM
          if is_premium?(event.bot, uid)
            begin
              user.pm("## 🎂 HAPPY BIRTHDAY!! #{EMOJI_STRINGS['neonsparkle']}\n\nIt's YOUR day, #{user.name}!! The Neon Arcade is throwing confetti in your honor! " \
                       "Here's **#{BIRTHDAY_REWARD}** #{EMOJI_STRINGS['s_coin']} as a birthday gift from yours truly~ 🌸\n\n*— Love, Blossom* #{EMOJI_STRINGS['hearts']}")
            rescue
              # DMs closed
            end
          end
        end
      rescue => e
        puts "[BIRTHDAY ERROR] #{e.message}"
      end
    end
  end

  # --- KO-FI SUBSCRIPTION EXPIRY CHECK ---
  Thread.new do
    loop do
      sleep(3600) # Check once per hour
      begin
        DB.expire_lapsed_subs
      rescue => e
        puts "[KOFI EXPIRY ERROR] #{e.message}"
      end
    end
  end

end