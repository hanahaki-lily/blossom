# ==========================================
# COMMAND: dice (High-Low Dice)
# DESCRIPTION: Roll 2d6 and bet on the outcome (High, Low, or Lucky 7).
# CATEGORY: Arcade
# ==========================================

# ------------------------------------------
# LOGIC: Dice Execution
# ------------------------------------------
def execute_dice(event, amount, bet)
  # 1. Initialization: Get user ID and normalize the bet string
  uid = event.user.id
  bet = bet.downcase

  # 2. Validation: Check for a valid amount and sufficient funds
  if amount <= 0 || DB.get_coins(uid) < amount
    return send_cv2(event, [{
      type: 17, accent_color: 0xFF0000,
      components: [
        { type: 10, content: "## ❌ Invalid Bet" },
        { type: 14, spacing: 1 },
        { type: 10, content: "You don't have enough coins or entered an invalid amount!" }
      ]
    }])
  end

  # 3. Validation: Ensure the bet type is recognized
  unless ['high', 'low', '7'].include?(bet)
    return send_cv2(event, [{
      type: 17, accent_color: 0xFF0000,
      components: [
        { type: 10, content: "## ❌ Invalid Bet Type" },
        { type: 14, spacing: 1 },
        { type: 10, content: "You can only bet on `high`, `low`, or `7`." }
      ]
    }])
  end

  # 4. Database: Deduct the initial bet amount
  DB.add_coins(uid, -amount)

  # 5. Simulation: Roll two 6-sided dice
  die1 = rand(1..6)
  die2 = rand(1..6)
  total = die1 + die2

  # 6. Logic: Categorize the actual result
  actual_result = total < 7 ? 'low' : (total > 7 ? 'high' : '7')

  # 7. Achievements
  check_achievement(event.channel, uid, 'dice_play')
  check_achievement(event.channel, uid, 'gamble_10k') if amount >= 10000

  # 8. Result: Handle the win/loss branching
  if bet == actual_result
    payout = (bet == '7') ? (amount * 4) : (amount * 2)
    DB.add_coins(uid, payout)
    check_achievement(event.channel, uid, 'dice_seven') if bet == '7'

    send_cv2(event, [{
      type: 17, accent_color: 0x00FF00,
      components: [
        { type: 10, content: "## 🎲 High Roller Dice" },
        { type: 14, spacing: 1 },
        { type: 10, content: "The dice roll... **#{die1}** and **#{die2}**! (Total: **#{total}**)\n\nYou correctly bet on **#{bet}** and won **#{payout}** 🪙!\nNew Balance: **#{DB.get_coins(uid)}** 🪙" }
      ]
    }])
  else
    check_achievement(event.channel, uid, 'gamble_broke') if amount >= 5000
    send_cv2(event, [{
      type: 17, accent_color: 0xFF0000,
      components: [
        { type: 10, content: "## 🎲 High Roller Dice" },
        { type: 14, spacing: 1 },
        { type: 10, content: "The dice roll... **#{die1}** and **#{die2}**! (Total: **#{total}**)\n\nYou bet on **#{bet}** and lost **#{amount}** 🪙.\nNew Balance: **#{DB.get_coins(uid)}** 🪙" }
      ]
    }])
  end
end

# ------------------------------------------
# TRIGGER: Prefix Command (b!dice)
# ------------------------------------------
$bot.command(:dice, 
  description: 'Roll 2d6! Bet on high (8-12), low (2-6), or 7.', 
  category: 'Arcade'
) do |event, amount_str, bet|
  # Argument Check: Ensure both inputs exist
  if amount_str.nil? || bet.nil?
    send_cv2(event, [{
      type: 17, accent_color: 0xFF0000,
      components: [
        { type: 10, content: "## 😕 Missing Arguments" },
        { type: 14, spacing: 1 },
        { type: 10, content: "Place your bets on the dice!\n\n**Usage:** `#{PREFIX}dice <amount> <high/low/7>`" }
      ]
    }])
    next
  end

  execute_dice(event, amount_str.to_i, bet)
  nil # Suppress default return
end

# ------------------------------------------
# TRIGGER: Slash Command (/dice)
# ------------------------------------------
$bot.application_command(:dice) do |event|
  # Slash commands handle data types automatically
  execute_dice(event, event.options['amount'], event.options['bet'])
end