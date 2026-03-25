def execute_daily(event)
  uid = event.user.id
  now = Time.now
  is_sub = is_premium?(event.bot, uid)
  
  # Initialize bonus_text as an empty string so we can add to it safely!
  bonus_text = ""
  
  daily_info = DB.get_daily_info(uid)
  
  # Ensure we handle nil values from the DB gracefully
  last_used = daily_info['at'] ? Time.parse(daily_info['at'].to_s) : nil
  current_streak = daily_info['streak'].to_i

  # 1. Cooldown Check
  if last_used && (now - last_used) < DAILY_COOLDOWN
    remaining = DAILY_COOLDOWN - (now - last_used)
    return send_embed(event, title: "#{EMOJIS['coin']} Daily Reward", description: "You already claimed your daily revenue! #{EMOJIS['worktired']}\nTry again in **#{format_time_delta(remaining)}**.")
  end

  # 2. Streak Logic
  if last_used.nil? || (now - last_used) > (DAILY_COOLDOWN * 2)
    new_streak = 1
    streak_msg = "\n*(Streak reset! Claim within 48h to build it up!)*"
  else
    new_streak = current_streak + 1
    streak_msg = "\n🔥 **Streak:** #{new_streak} days!"
  end

  # 3. Base Reward Calculation
  # Bonus: +50 coins per day of streak
  reward = DAILY_REWARD + (new_streak * 50) 
  
  # 4. Premium / Prisma Logic
  if is_sub
    base_prisma = rand(1..3)
    # The Multiplier: +1x Prisma for every 7 days of streak
    streak_multiplier = 1 + (new_streak / 7)
    prisma_reward = base_prisma * streak_multiplier
    
    DB.add_prisma(uid, prisma_reward)
    
    bonus_text += "\n*(<:prisma:1486142162805723196> Subscriber Bonus: +10% Coins & +#{prisma_reward} Prisma!)*"
  end
  
  # 5. Inventory Boosts
  inv = DB.get_inventory(uid)
  if inv['neon sign'] && inv['neon sign'] > 0
    reward *= 2
    bonus_text += "\n*(✨ Neon Sign Boost: x2 Payout!)*"
  end

  # 6. Final Granting
  # award_coins handles the +10% multiplier for premium users automatically
  final_reward = award_coins(event.bot, uid, reward)
  DB.update_daily_claim(uid, new_streak, now)

  # 7. Achievement Checks
  check_achievement(event.channel, uid, 'streak_7') if new_streak == 7
  check_achievement(event.channel, uid, 'streak_30') if new_streak == 30
  check_achievement(event.channel, uid, 'streak_69') if new_streak == 69
  check_achievement(event.channel, uid, 'streak_100') if new_streak == 100
  check_achievement(event.channel, uid, 'streak_365') if new_streak == 365
  
  # 8. Send the Response
  send_embed(
    event, 
    title: "#{EMOJIS['coin']} Daily Reward", 
    description: "You claimed **#{final_reward}** #{EMOJIS['s_coin']}!#{streak_msg}#{bonus_text}\n\nNew balance: **#{DB.get_coins(uid)}** #{EMOJIS['s_coin']}."
  )
end

bot.command(:daily, description: 'Claim your daily coin reward', category: 'Economy') { |e| execute_daily(e); nil }
bot.application_command(:daily) { |e| execute_daily(e) }