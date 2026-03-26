# ==========================================
# COMMAND: coinflip
# DESCRIPTION: A high-stakes gamble where users bet coins on a 50/50 flip.
# CATEGORY: Arcade
# ==========================================

# ------------------------------------------
# LOGIC: Coinflip Execution
# ------------------------------------------
def execute_coinflip(event, amount, choice)
  # 1. Initialization: Standardize the user's input
  uid = event.user.id
  choice = choice.downcase

  # 2. Validation: Ensure the bet is a positive number
  if amount <= 0
    return send_cv2(event, [{
      type: 17, accent_color: 0xFF0000,
      components: [
        { type: 10, content: "## ❌ Invalid Bet" },
        { type: 14, spacing: 1 },
        { type: 10, content: "You must bet at least 1 🪙." }
      ]
    }])
  end

  # 3. Validation: Check the user's balance in the Database
  if DB.get_coins(uid) < amount
    return send_cv2(event, [{
      type: 17, accent_color: 0xFF0000,
      components: [
        { type: 10, content: "## 😰 Insufficient Funds" },
        { type: 14, spacing: 1 },
        { type: 10, content: "You don't have enough coins to cover that bet!\nYou currently have **#{DB.get_coins(uid)}** 🪙." }
      ]
    }])
  end

  # 4. Validation: Ensure the choice is valid (Heads or Tails)
  unless ['heads', 'tails'].include?(choice)
    return send_cv2(event, [{
      type: 17, accent_color: 0xFF0000,
      components: [
        { type: 10, content: "## ❌ Invalid Choice" },
        { type: 14, spacing: 1 },
        { type: 10, content: "Please pick either `heads` or `tails`." }
      ]
    }])
  end

  # 5. Calculation: Determine the result and deduct the initial bet
  result = ['heads', 'tails'].sample
  DB.add_coins(uid, -amount)
  check_achievement(event.channel, uid, 'gamble_10k') if amount >= 10000

  # 6. Result: Handle the Win/Loss scenarios
  if choice == result
    DB.add_coins(uid, amount * 2)
    send_cv2(event, [{
      type: 17, accent_color: 0x00FF00,
      components: [
        { type: 10, content: "## 🪙 Coinflip: #{result.capitalize}!" },
        { type: 14, spacing: 1 },
        { type: 10, content: "You won! You doubled your bet and earned **#{amount}** 🪙.\nNew Balance: **#{DB.get_coins(uid)}** 🪙" }
      ]
    }])
    check_achievement(event.channel, uid, 'gamble_win')
  else
    check_achievement(event.channel, uid, 'gamble_broke') if amount >= 5000
    send_cv2(event, [{
      type: 17, accent_color: 0xFF0000,
      components: [
        { type: 10, content: "## 🪙 Coinflip: #{result.capitalize}!" },
        { type: 14, spacing: 1 },
        { type: 10, content: "You lost... **#{amount}** 🪙 down the drain.\nNew Balance: **#{DB.get_coins(uid)}** 🪙" }
      ]
    }])
  end
end

# ------------------------------------------
# TRIGGER: Prefix Command (b!coinflip)
# ------------------------------------------
$bot.command(:coinflip, 
  description: 'Bet your stream revenue on a coinflip!', 
  category: 'Arcade'
) do |event, amount_str, choice|
  # Argument Check: Ensure both amount and choice are present
  if amount_str.nil? || choice.nil?
    send_cv2(event, [{
      type: 17, accent_color: 0xFF0000,
      components: [
        { type: 10, content: "## 😕 Missing Arguments" },
        { type: 14, spacing: 1 },
        { type: 10, content: "You need to tell me how much to bet and what side you want!\n\n**Usage:** `#{PREFIX}coinflip <amount> <heads/tails>`" }
      ]
    }])
    next
  end

  execute_coinflip(event, amount_str.to_i, choice)
  nil # Suppress default return
end

# ------------------------------------------
# TRIGGER: Slash Command (/coinflip)
# ------------------------------------------
$bot.application_command(:coinflip) do |event|
  # Options are automatically cast to the correct type by discordrb for Slash
  execute_coinflip(event, event.options['amount'], event.options['choice'])
end