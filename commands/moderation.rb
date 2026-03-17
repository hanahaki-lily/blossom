module Moderation
  extend Discordrb::Commands::CommandContainer
  extend Discordrb::EventContainer

  def self.parse_member(event, input)
    return nil unless input
    id = input.to_s.gsub(/[^\d]/, '').to_i
    event.server.member(id)
  end

  def self.parse_id(input)
    return nil unless input
    id = input.to_s.gsub(/[^\d]/, '').to_i
    id > 0 ? id : nil
  end

  def self.reply(event, text, is_ephemeral: false)
    if event.is_a?(Discordrb::Events::ApplicationCommandEvent)
      event.respond(content: text, ephemeral: is_ephemeral)
    else
      msg = event.respond(text)
      if text.include?("swept away") && !is_ephemeral
        sleep 3
        msg.delete rescue nil
      end
    end
  end

  # ==========================================
  # CORE ENGINES
  # ==========================================
  
  def self.execute_purge(event, amount)
    return reply(event, "❌ *You don't have permission to do that!*", is_ephemeral: true) unless event.user.permission?(:manage_messages, event.channel)
    
    amt = amount.to_i
    return reply(event, "🌸 *Please provide a number between 1 and 100!*", is_ephemeral: true) unless amt.between?(1, 100)

    is_slash = event.is_a?(Discordrb::Events::ApplicationCommandEvent)
    
    event.defer(ephemeral: true) if is_slash

    begin
      delete_count = is_slash ? amt : amt + 1
      event.channel.prune(delete_count)
      
      success_msg = "🧹 Successfully swept away #{amt} messages!"
      
      if is_slash
        event.edit_response(content: success_msg)
      else
        msg = event.respond(success_msg)
        sleep 3
        msg.delete rescue nil
      end
    rescue => e
      error_msg = "❌ *I couldn't delete messages! Error:* `#{e.message}`"
      if is_slash
        event.edit_response(content: error_msg)
      else
        reply(event, error_msg, is_ephemeral: true)
      end
    end
  end

  def self.execute_kick(event, member, reason)
    return reply(event, "❌ *You don't have permission to do that!*", is_ephemeral: true) unless event.user.permission?(:kick_members)
    return reply(event, "🌸 *I couldn't find that user in this server!*", is_ephemeral: true) unless member
    
    reason = "No reason provided." if reason.nil? || reason.to_s.strip.empty?

    begin
      event.server.kick(member, reason)
      reply(event, "👢 Successfully kicked **#{member.display_name}**.\n*Reason:* #{reason}")
    rescue => e
      reply(event, "❌ *Action Failed! Error:* `#{e.message}`\n*(Make sure my Bot Role is placed higher than theirs!)*", is_ephemeral: true)
    end
  end

  def self.execute_ban(event, user_input, reason)
    return reply(event, "❌ *You don't have permission to do that!*", is_ephemeral: true) unless event.user.permission?(:ban_members)
    
    target_id = parse_id(user_input)
    return reply(event, "🌸 *Please provide a valid user ID or mention!*", is_ephemeral: true) unless target_id
    
    reason = "No reason provided." if reason.nil? || reason.to_s.strip.empty?

    begin
      event.server.ban(target_id, 0, reason: reason)
      reply(event, "🔨 Successfully banned ID **#{target_id}**.\n*Reason:* #{reason}")
    rescue => e
      reply(event, "❌ *Action Failed! Error:* `#{e.message}`\n*(Make sure my Bot Role is placed higher than theirs, and the ID is valid!)*", is_ephemeral: true)
    end
  end

  def self.execute_timeout(event, member, minutes, reason)
    return reply(event, "❌ *You don't have permission to do that!*", is_ephemeral: true) unless event.user.permission?(:moderate_members) || event.user.permission?(:kick_members)
    return reply(event, "🌸 *I couldn't find that user in this server!*", is_ephemeral: true) unless member
    
    mins = minutes.to_i
    return reply(event, "🌸 *Please provide a valid number of minutes!*", is_ephemeral: true) if mins <= 0

    reason = "No reason provided." if reason.nil? || reason.to_s.strip.empty?
    
    expire_time = (Time.now.utc + (mins * 60)).iso8601

    begin
      Discordrb::API::Server.update_member(
        event.bot.token,
        event.server.id,
        member.id,
        communication_disabled_until: expire_time,
        reason: reason
      )
      
      reply(event, "⏱️ **#{member.display_name}** has been timed out for #{mins} minutes.\n*Reason:* #{reason}")
    rescue => e
      reply(event, "❌ *Action Failed! Error:* `#{e.message}`\n*(Make sure my Bot Role is placed higher than theirs!)*", is_ephemeral: true)
    end
  end

  # ==========================================
  # PREFIX COMMAND LISTENERS (b!ban)
  # ==========================================

  command(:purge, description: 'Deletes a number of messages', required_permissions: [:manage_messages]) do |event, amount|
    execute_purge(event, amount)
    nil
  end

  command(:kick, description: 'Kicks a user', required_permissions: [:kick_members]) do |event, user_input, *reason_array|
    member = parse_member(event, user_input)
    reason = reason_array.join(' ')
    execute_kick(event, member, reason)
    nil
  end

  command(:ban, description: 'Bans a user (or ID)', required_permissions: [:ban_members]) do |event, user_input, *reason_array|
    reason = reason_array.join(' ')
    execute_ban(event, user_input, reason)
    nil
  end

  command(:timeout, description: 'Timeouts a user', required_permissions: [:moderate_members]) do |event, user_input, minutes, *reason_array|
    member = parse_member(event, user_input)
    reason = reason_array.join(' ')
    execute_timeout(event, member, minutes, reason)
    nil
  end

  # ==========================================
  # SLASH COMMAND LISTENERS (/ban)
  # ==========================================

  application_command(:purge) do |event|
    execute_purge(event, event.options['amount'])
  end

  application_command(:kick) do |event|
    member = parse_member(event, event.options['user'])
    execute_kick(event, member, event.options['reason'])
  end

  application_command(:ban) do |event|
    execute_ban(event, event.options['user'], event.options['reason'])
  end

  application_command(:timeout) do |event|
    member = parse_member(event, event.options['user'])
    execute_timeout(event, member, event.options['minutes'], event.options['reason'])
  end

end