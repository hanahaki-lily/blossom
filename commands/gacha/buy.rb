# ==========================================
# COMMAND: buy
# DESCRIPTION: Purchase tech upgrades, consumables, or direct characters from the shop.
# CATEGORY: Economy / Gacha
# ==========================================

# ------------------------------------------
# LOGIC: Shop Execution
# ------------------------------------------
def execute_buy(event, search_name)
  # 1. Validation: Ensure an item name was provided
  if search_name.nil? || search_name.strip.empty?
    return send_cv2(event, [{ type: 17, accent_color: NEON_COLORS.sample, components: [
      { type: 10, content: "## ⚠️ Missing Name" },
      { type: 14, spacing: 1 },
      { type: 10, content: "Who or what do you want to buy?" }
    ]}])
  end

  # 2. Initialization: Normalize search strings
  uid = event.user.id
  search_name = search_name.downcase.strip

  # 3. Branch: Event Exclusive Characters
  # Prevents users from bypassing the Event Hub during seasonal events.
  if is_event_character?(search_name)
    display_name = search_name.split.map(&:capitalize).join(' ') 
    return send_cv2(event, [{ type: 17, accent_color: NEON_COLORS.sample, components: [
      { type: 10, content: "## 🎪 Event Exclusive!" },
      { type: 14, spacing: 1 },
      { type: 10, content: "**#{display_name}** is a limited-time event character!\n\nYou can only purchase them from the Event Hub using #{SPRING_CARNIVAL[:emoji]}." }
    ]}])
  end

  # 4. Branch: Black Market Items (Upgrades & Consumables)
  if BLACK_MARKET_ITEMS.key?(search_name)
    item_data = BLACK_MARKET_ITEMS[search_name]
    price = item_data[:price]

    # A. Funds Check
    if DB.get_coins(uid) < price
      return send_cv2(event, [{ type: 17, accent_color: NEON_COLORS.sample, components: [
        { type: 10, content: "## 😰 Insufficient Funds" },
        { type: 14, spacing: 1 },
        { type: 10, content: "You need **#{price}** coins to buy the #{item_data[:name]}.\nYou currently have **#{DB.get_coins(uid)}** coins." }
      ]}])
    end

    # B. Ownership Check: Prevent duplicate upgrades (Mic, Keyboard, etc.)
    inv_array = DB.get_inventory(uid)
    inv = inv_array.each_with_object({}) { |item, h| h[item['item_id']] = item['quantity'] }
    if item_data[:type] == 'upgrade' && inv[search_name] && inv[search_name] >= 1
      return send_cv2(event, [{ type: 17, accent_color: NEON_COLORS.sample, components: [
        { type: 10, content: "## 😕 Already Owned" },
        { type: 14, spacing: 1 },
        { type: 10, content: "You already have the **#{item_data[:name]}** equipped in your setup!" }
      ]}])
    end

    # C. Transaction: Deduct coins and add to inventory
    DB.add_coins(uid, -price)
    DB.add_inventory(uid, search_name, 1)

    # D. Progression: Achievement Milestones
    if item_data[:type] == 'upgrade'
      check_achievement(event.channel, uid, 'buy_upgrade')
    elsif item_data[:type] == 'consumable'
      check_achievement(event.channel, uid, 'buy_consumable')
    end

    # E. Effect Logic: Immediate use of consumables
    if search_name == 'gamer fuel'
      DB.remove_inventory(uid, search_name, 1)
      ['stream', 'post', 'collab'].each { |cd| DB.set_cooldown(uid, cd, nil) }
      check_achievement(event.channel, uid, 'use_fuel')
      return send_cv2(event, [{ type: 17, accent_color: NEON_COLORS.sample, components: [
        { type: 10, content: "## 🥫 Gamer Fuel Consumed!" },
        { type: 14, spacing: 1 },
        { type: 10, content: "You cracked open a cold one and chugged it.\n**ALL your content creation cooldowns have been reset!** Get back to the grind." }
      ]}])

    elsif search_name == 'stamina pill'
      DB.remove_inventory(uid, search_name, 1)
      DB.set_cooldown(uid, 'summon', nil)
      check_achievement(event.channel, uid, 'use_pill')
      return send_cv2(event, [{ type: 17, accent_color: NEON_COLORS.sample, components: [
        { type: 10, content: "## 💊 Stamina Pill Swallowed!" },
        { type: 14, spacing: 1 },
        { type: 10, content: "You took a highly questionable Stamina Pill...\n**Your !summon cooldown has been instantly reset!** Get back to gambling." }
      ]}])

    elsif search_name == 'rng manipulator'
      check_achievement(event.channel, uid, 'use_rng')
    end

    return send_cv2(event, [{ type: 17, accent_color: NEON_COLORS.sample, components: [
      { type: 10, content: "## 🛒 Item Purchased!" },
      { type: 14, spacing: 1 },
      { type: 10, content: "You successfully bought the **#{item_data[:name]}** for **#{price}** coins!\nIt has been added to your inventory/setup." }
    ]}])
  end

  # 5. Branch: Direct Character Purchase (Pity System)
  result = find_character_in_pools(search_name)
  unless result
    return send_cv2(event, [{ type: 17, accent_color: NEON_COLORS.sample, components: [
      { type: 10, content: "## ❌ Shop Error" },
      { type: 14, spacing: 1 },
      { type: 10, content: "I couldn't find a character or item named **#{search_name}**. Check your spelling!" }
    ]}])
  end

  char_data = result[:char]
  rarity    = result[:rarity]
  price     = SHOP_PRICES[rarity]

  # A. Goddess characters cost Prisma, not coins
  if rarity == 'goddess'
    prisma_price = GODDESS_PRISMA_PRICE
    prisma_bal = DB.get_prisma(uid)

    if prisma_bal < prisma_price
      return send_cv2(event, [{ type: 17, accent_color: NEON_COLORS.sample, components: [
        { type: 10, content: "## 💎 Not Enough Prisma" },
        { type: 14, spacing: 1 },
        { type: 10, content: "**#{char_data[:name]}** is a Goddess-tier character and costs **#{prisma_price}** Prisma.\nYou currently have **#{prisma_bal}** Prisma.\n\n*Earn Prisma through premium rewards and special events!*" }
      ]}])
    end

    DB.add_prisma(uid, -prisma_price)
    name = char_data[:name]
    DB.add_character(uid, name, rarity.to_s, 1)
    new_count = DB.get_collection(uid)[name]['count']
    check_achievement(event.channel, uid, 'first_goddess_buy')

    return send_cv2(event, [{ type: 17, accent_color: NEON_COLORS.sample, components: [
      { type: 10, content: "## 💎 Goddess Acquired!" },
      { type: 14, spacing: 1 },
      { type: 10, content: "💎 You purchased **#{name}** for **#{prisma_price}** Prisma!\nYou now own **#{new_count}** of them." },
      { type: 14, spacing: 1 },
      { type: 10, content: "**Remaining Prisma:** #{DB.get_prisma(uid)} Prisma" }
    ]}])
  end

  # B. Pricing Check: Some rarities may not be directly purchasable
  if price.nil?
    return send_cv2(event, [{ type: 17, accent_color: NEON_COLORS.sample, components: [
      { type: 10, content: "## ❌ Black Market Locked" },
      { type: 14, spacing: 1 },
      { type: 10, content: "You cannot directly purchase **#{char_data[:name]}**. She can only be obtained through the gacha portal." }
    ]}])
  end

  # C. Funds Check
  if DB.get_coins(uid) < price
    return send_cv2(event, [{ type: 17, accent_color: NEON_COLORS.sample, components: [
      { type: 10, content: "## 😰 Insufficient Funds" },
      { type: 14, spacing: 1 },
      { type: 10, content: "You need **#{price}** coins to buy a #{rarity.capitalize} character.\nYou currently have **#{DB.get_coins(uid)}** coins." }
    ]}])
  end

  # D. Transaction & UI Response
  DB.add_coins(uid, -price)
  name = char_data[:name]
  DB.add_character(uid, name, rarity.to_s, 1)
  new_count = DB.get_collection(uid)[name]['count']

  emoji = { 'goddess' => '💎', 'legendary' => '🌟', 'rare' => '✨' }.fetch(rarity, '⭐')

  send_cv2(event, [{ type: 17, accent_color: NEON_COLORS.sample, components: [
    { type: 10, content: "## 🪙 Purchase Successful!" },
    { type: 14, spacing: 1 },
    { type: 10, content: "#{emoji} You directly purchased **#{name}** for **#{price}** coins!\nYou now own **#{new_count}** of them." },
    { type: 14, spacing: 1 },
    { type: 10, content: "**Remaining Balance:** #{DB.get_coins(uid)} coins" }
  ]}])
end

# ------------------------------------------
# TRIGGERS: Prefix & Slash
# ------------------------------------------
$bot.command(:buy, description: 'Buy a character or tech upgrade', min_args: 1, category: 'Economy') do |event, *name_args|
  execute_buy(event, name_args.join(' '))
  nil
end

$bot.application_command(:buy) do |event|
  execute_buy(event, event.options['item'])
end