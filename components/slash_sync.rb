# frozen_string_literal: true

require 'json'
require 'digest'

require_relative 'slash_definitions'

# Compares Blossom's canonical slash schema to Discord's registered global commands.
# Bulk-overwrites only when they differ (one PUT), or when BLOSSOM_SLASH_SYNC=force.
#
# Env:
#   BLOSSOM_SLASH_SYNC=auto   — default: fetch, compare, PUT if needed
#   BLOSSOM_SLASH_SYNC=never  — skip all HTTP (offline / avoid rate limits)
#   BLOSSOM_SLASH_SYNC=force  — always bulk overwrite
module BlossomSlashSync
  OPTION_KEYS = %w[
    type name description required choices options
    min_value max_value min_length max_length channel_types autocomplete
  ].freeze

  module_function

  def normalize_option(opt)
    h = {}
    OPTION_KEYS.each do |k|
      next unless opt.key?(k)

      v = opt[k]
      case k
      when 'options'
        h['options'] = normalize_option_list(v)
      when 'choices'
        h['choices'] = Array(v).map { |ch| stringify_keys(ch).slice('name', 'value') }.compact.sort_by { |ch| ch['name'].to_s }
      else
        h[k] = v
      end
    end
    h
  end

  def normalize_option_list(raw)
    return [] if raw.nil? || raw == []

    arr = raw.is_a?(Array) ? raw : []
    norm = arr.map { |o| normalize_option(stringify_keys(o)) }
    norm.sort_by! { |o| o['name'].to_s }
    norm.each { |o| o['options'] = normalize_option_list(o['options']) if o['options'] }
    norm
  end

  def stringify_keys(obj)
    case obj
    when Hash
      obj.to_h { |k, val| [k.to_s, val] }
    else
      obj
    end
  end

  def normalize_command(raw)
    c = stringify_keys(raw)
    {
      'type' => (c['type'] || 1).to_i,
      'name' => c['name'].to_s,
      'description' => c.fetch('description', '').to_s,
      'options' => normalize_option_list(c['options'].is_a?(Array) ? c['options'] : [])
    }
  end

  def deep_sort_keys(obj)
    case obj
    when Hash
      obj.keys.sort.each_with_object({}) { |k, h| h[k] = deep_sort_keys(obj[k]) }
    when Array
      obj.map { |e| deep_sort_keys(e) }
    else
      obj
    end
  end

  def canonical_command_set(commands_array)
    list = commands_array.map { |c| normalize_command(c) }
    list.sort_by! { |x| x['name'] }
    Digest::SHA256.hexdigest(JSON.generate(deep_sort_keys(list)))
  end

  def sync_global_application_commands(bot)
    mode = ENV['BLOSSOM_SLASH_SYNC']&.strip&.downcase
    mode = 'auto' if mode.nil? || mode.empty?

    if mode == 'never'
      puts '🌸 Slash sync skipped (BLOSSOM_SLASH_SYNC=never).'
      return
    end

    desired = BlossomSlashDefinitions.global_application_commands

    resp = Discordrb::API::Application.get_global_commands(bot.token, bot.profile.id)
    remote_raw = JSON.parse(resp)
    unless remote_raw.is_a?(Array)
      puts '[SLASH SYNC] Unexpected GET /commands response; skipping.'
      return
    end

    digest_local = canonical_command_set(desired)
    digest_remote = canonical_command_set(remote_raw)

    if mode != 'force' && digest_local == digest_remote
      puts '🌸 Slash commands already match Discord — no registration API call.'
      return
    end

    if mode == 'force'
      puts '🌸 Slash sync: BLOSSOM_SLASH_SYNC=force — bulk overwriting global commands...'
    else
      puts '🌸 Slash sync: schema changed — bulk overwriting global commands...'
    end

    Discordrb::API::Application.bulk_overwrite_global_commands(bot.token, bot.profile.id, desired)
    puts "✅ Slash sync: registered #{desired.size} global command(s)."
  rescue StandardError => e
    puts "[SLASH SYNC] #{e.class}: #{e.message}"
    puts e.backtrace&.first(5)&.map { |ln| "    #{ln}" }&.join("\n")
  end
end
