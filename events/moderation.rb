# =========================
# MESSAGE MEMORY CACHE
# =========================
BLOSSOM_CACHE = {}
MAX_CACHE_SIZE = 1000

bot.message do |event|
  next unless event.server

  BLOSSOM_CACHE[event.message.id] = {
    content: event.message.content,
    author_mention: event.message.author.mention,
    author_tag: event.message.author.distinct
  }

  if BLOSSOM_CACHE.size > MAX_CACHE_SIZE
    oldest_keys = BLOSSOM_CACHE.keys.first(100)
    oldest_keys.each { |k| BLOSSOM_CACHE.delete(k) }
  end
end

# =========================
# MESSAGE DELETE LOGGING
# =========================
bot.message_delete do |event|
  next unless event.server
  
  config = DB.get_log_config(event.server.id)
  next unless config[:deletes] && config[:channel]

  log_channel = bot.channel(config[:channel])
  next unless log_channel

  cached_msg = BLOSSOM_CACHE[event.id]
  
  if cached_msg
    content = cached_msg[:content].strip.empty? ? "*[No text - likely an image or embed]*" : cached_msg[:content][0..1000]
    author = "#{cached_msg[:author_mention]} *(#{cached_msg[:author_tag]})*"
  else
    content = "*Message was sent before Blossom booted up, or fell out of her memory cache.*"
    author = "Unknown User"
  end

  embed = Discordrb::Webhooks::Embed.new(
    title: "🗑️ Message Deleted",
    description: "**Author:** #{author}\n**Channel:** <##{event.channel.id}>\n\n**Content:**\n#{content}",
    color: 0xFF0000, 
    timestamp: Time.now
  )

  begin
    log_channel.send_message(nil, false, embed)
  rescue => e
  end
end

# =========================
# MESSAGE EDIT LOGGING
# =========================
bot.message_edit do |event|
  next unless event.server
  next if event.message.author.bot_account?

  config = DB.get_log_config(event.server.id)
  next unless config[:edits] && config[:channel]

  log_channel = bot.channel(config[:channel])
  next unless log_channel

  cached_msg = BLOSSOM_CACHE[event.message.id]
  old_content = cached_msg ? cached_msg[:content] : "*[Message was sent before Blossom cached it]*"
  new_content = event.message.content

  next if old_content == new_content

  if cached_msg
    BLOSSOM_CACHE[event.message.id][:content] = new_content
  end

  embed = Discordrb::Webhooks::Embed.new(
    title: "✏️ Message Edited",
    description: "**Author:** #{event.message.author.mention}\n**Channel:** <##{event.channel.id}>\n[Jump to Message](#{event.message.link})\n\n**Before:**\n#{old_content[0..500]}\n\n**After:**\n#{new_content[0..500]}",
    color: 0xFFA500, 
    timestamp: Time.now
  )

  begin
    log_channel.send_message(nil, false, embed)
  rescue => e
  end
end