# ==========================================
# COMPONENT: Top.gg webhook HTTP listener (WEBrick)
# Requires TOPGG_WEBHOOK_SECRET. Optional: TOPGG_WEBHOOK_PORT (default 8081),
# TOPGG_WEBHOOK_BIND (default 0.0.0.0), TOPGG_BOT_DISCORD_ID to verify project.
# ==========================================

require 'webrick'
require 'json'
require 'digest'
require_relative '../helpers/topgg'

module TopggWebhookServer
  module_function

  def start!
    secret = ENV['TOPGG_WEBHOOK_SECRET'].to_s.strip
    return if secret.empty?

    port = ENV.fetch('TOPGG_WEBHOOK_PORT', '8081').to_i
    bind = ENV.fetch('TOPGG_WEBHOOK_BIND', '0.0.0.0')

    Thread.new do
      server = WEBrick::HTTPServer.new(
        Port: port,
        BindAddress: bind,
        Logger: WEBrick::Log.new($stdout),
        AccessLog: []
      )

      server.mount_proc('/webhooks/topgg') do |req, res|
        TopggWebhookServer.handle_request(req, res, secret)
      end

      puts "\u{1F338} [TOP.GG] Webhook server listening on http://#{bind}:#{port}/webhooks/topgg"

      server.start
    rescue StandardError => e
      puts "[TOP.GG] Webhook server failed: #{e.class}: #{e.message}"
    end
  end

  def handle_request(req, res, secret)
    res['Content-Type'] = 'text/plain'

    unless req.request_method == 'POST'
      res.status = 405
      res.body = 'Method Not Allowed'
      return
    end

    raw = req.body
    raw = raw.string if raw.respond_to?(:string) && raw.is_a?(StringIO)
    raw = raw.read if raw.respond_to?(:read) && !raw.is_a?(String)
    raw = raw.to_s

    sig_header = req['x-topgg-signature'] || req['X-Topgg-Signature']

    v1_ok = TopggWebhook.signature_valid?(raw, sig_header.to_s, secret)
    v0_ok = !v1_ok && TopggWebhook.legacy_authorized?(req, secret)

    unless v1_ok || v0_ok
      res.status = 401
      res.body = 'Unauthorized'
      return
    end

    payload = JSON.parse(raw)
    kind = payload['type'].to_s

    if kind == 'vote.create'
      handle_vote_create(payload, raw)
    elsif kind == 'webhook.test'
      # dashboard ping only
    elsif v0_ok && %w[upvote test].include?(payload['type'].to_s)
      handle_vote_v0(payload, raw)
    end

    res.status = 200
    res.body = 'ok'
  rescue JSON::ParserError
    res.status = 400
    res.body = 'bad json'
  rescue StandardError => e
    puts "[TOP.GG] Webhook handler error: #{e.class}: #{e.message}"
    res.status = 500
    res.body = 'error'
  end

  def handle_vote_create(payload, _raw_body)
    data = payload['data'] || {}
    vote_id = data['id'].to_s
    return if vote_id.empty?

    expected_bot = ENV['TOPGG_BOT_DISCORD_ID'].to_s.strip
    bot_ok = expected_bot.empty? || data.dig('project', 'platform_id').to_s == expected_bot
    unless bot_ok
      puts '[TOP.GG] Rejected vote: project platform_id mismatch'
      return
    end

    uid = data.dig('user', 'platform_id')
    weight = (data['weight'] || 1).to_i
    next_after = parse_iso_time(data['expires_at'])

    result = DB.apply_topgg_vote(
      vote_id: vote_id,
      discord_uid: uid,
      weight: weight,
      next_vote_after: next_after
    )

    log_vote_result(result, vote_id)
  rescue StandardError => e
    puts "[TOP.GG] vote.create error: #{e.class}: #{e.message}"
    raise
  end

  def handle_vote_v0(payload, raw_body)
    return if payload['type'].to_s == 'test'

    vote_id = Digest::SHA256.hexdigest(raw_body)
    expected_bot = ENV['TOPGG_BOT_DISCORD_ID'].to_s.strip
    bot_ok = expected_bot.empty? || payload['bot'].to_s == expected_bot
    unless bot_ok
      puts '[TOP.GG] Rejected v0 vote: bot id mismatch'
      return
    end

    uid = payload['user']
    weight = payload['isWeekend'] ? 2 : 1
    next_after = Time.now + (12 * 3600)

    result = DB.apply_topgg_vote(
      vote_id: "v0-#{vote_id}",
      discord_uid: uid,
      weight: weight,
      next_vote_after: next_after
    )
    log_vote_result(result, vote_id)
  end

  def parse_iso_time(str)
    return nil if str.nil? || str.to_s.empty?

    Time.parse(str.to_s)
  rescue ArgumentError
    nil
  end

  def log_vote_result(result, vote_id)
    case result[:status]
    when :duplicate
      puts "[TOP.GG] Duplicate webhook #{vote_id} (ignored)"
    when :skipped_blacklist
      puts "[TOP.GG] Vote #{vote_id} recorded; user blacklisted (no Prisma)"
    when :reject
      puts "[TOP.GG] Vote #{vote_id} ignored (invalid user id)"
    when :ok
      puts "[TOP.GG] Vote #{vote_id} -> +#{result[:prisma]} Prisma (streak grant #{result[:streak_used]}, stored #{result[:streak]})"
    end
  end
end
