# ==========================================
# SYSTEM: Ko-fi Webhook Server
# DESCRIPTION: Sinatra micro-server that receives Ko-fi
# payment webhooks and auto-grants premium subscriptions.
# ==========================================

require 'sinatra/base'
require 'json'

class KofiWebhook < Sinatra::Base
  set :port, ENV.fetch('KOFI_WEBHOOK_PORT', 4567).to_i
  set :bind, '0.0.0.0'
  set :logging, true

  # Ko-fi sends form-encoded POST with a 'data' field containing JSON
  post '/kofi' do
    raw = params['data']
    unless raw
      puts "[KO-FI] ❌ No 'data' field in request body"
      halt 400, 'Bad request'
    end

    begin
      payload = JSON.parse(raw)
    rescue JSON::ParserError
      puts "[KO-FI] ❌ Failed to parse JSON payload"
      halt 400, 'Invalid JSON'
    end

    # Verify the token matches our Ko-fi webhook secret
    unless payload['verification_token'] == ENV['KOFI_VERIFICATION_TOKEN']
      puts "[KO-FI] ❌ Invalid verification token"
      halt 403, 'Forbidden'
    end

    email = payload['email']&.downcase&.strip
    from_name = payload['from_name'] || 'Unknown'
    type = payload['type']
    amount = payload['amount']
    transaction_id = payload['kofi_transaction_id']
    tier_name = payload['tier_name']
    is_sub = payload['is_subscription_payment']
    is_first_sub = payload['is_first_subscription_payment']

    puts "[KO-FI] 📨 Received #{type} from #{from_name} (#{email}) — $#{amount}"

    case type
    when 'Subscription'
      handle_subscription(email, from_name, transaction_id, tier_name, is_first_sub)
    when 'Donation'
      handle_donation(email, from_name, amount, transaction_id)
    end

    status 200
    body 'OK'
  end

  # Health check endpoint
  get '/kofi/health' do
    status 200
    body 'Blossom Ko-fi webhook is alive!'
  end

  private

  def handle_subscription(email, from_name, transaction_id, tier_name, is_first)
    user_id = DB.find_user_by_kofi_email(email)

    unless user_id
      puts "[KO-FI] ⚠️  No linked Discord account for #{email} (#{from_name}). Sub payment received but cannot grant premium."
      return
    end

    # Grant 35 days (monthly + 5 day grace period for renewal lag)
    DB.extend_premium_sub(user_id, transaction_id, 35)

    action = is_first ? "NEW subscription" : "renewed subscription"
    tier_info = tier_name ? " (#{tier_name})" : ""
    puts "[KO-FI] ✅ #{action} for Discord user #{user_id}#{tier_info} — premium extended 35 days"

    # Send a DM to the user if the bot is available
    notify_user(user_id, is_first, tier_name)
  end

  def handle_donation(email, from_name, amount, transaction_id)
    user_id = DB.find_user_by_kofi_email(email)
    puts "[KO-FI] 💰 Donation of $#{amount} from #{from_name} (#{email})"

    if user_id
      # Award bonus coins for donations (100 coins per dollar)
      bonus = (amount.to_f * 100).to_i
      DB.add_coins(user_id, bonus)
      puts "[KO-FI] 🎁 Awarded #{bonus} bonus coins to Discord user #{user_id}"
    else
      puts "[KO-FI] ⚠️  No linked Discord account for #{email} — donation logged but no coins awarded"
    end
  end

  def notify_user(user_id, is_first, tier_name)
    return unless defined?($bot) && $bot

    Thread.new do
      begin
        user = $bot.user(user_id)
        return unless user

        if is_first
          user.dm("## 🌸 Welcome to Neon Arcade Premium!\n\nYour Ko-fi subscription just kicked in and you're officially VIP, bestie. Here's what you just unlocked:\n\n• **50% shorter cooldowns** on all economy commands\n• **+10% bonus coins** on every payout\n• **1.5x XP gain** per message\n• **Prisma currency** earnings\n• **Gacha pity system** + shiny pulls\n• **Profile customization** (bio, color, favorite cards)\n• ...and more!\n\nThanks for supporting the Arcade. You're built different. 💜")
        else
          user.dm("## 🌸 Premium Renewed!\n\nYour Ko-fi sub just renewed — you're locked in for another month of VIP treatment. Thanks for keeping the lights on at the Arcade, bestie! 💜")
        end
      rescue => e
        puts "[KO-FI] ⚠️  Could not DM user #{user_id}: #{e.message}"
      end
    end
  end
end
