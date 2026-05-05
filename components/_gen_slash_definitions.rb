# frozen_string_literal: true
# One-shot helper: regenerate slash_definitions.rb — run from components/: ruby _gen_slash_definitions.rb

reg = File.readlines(File.join(__dir__, 'slash_registry.rb'), encoding: 'UTF-8')
beg_i = reg.index { |l| l.strip == '=begin' }
end_i = reg.index { |l| l.strip == '=end' }
abort('slash_registry: missing =begin/=end') unless beg_i && end_i && end_i > beg_i

inner = reg[(beg_i + 1)...end_i].join

body = inner
       .sub(/\A\s*puts[^\n]+\n+/m, '')
       .sub(/\s*\nputs[^\n]+application commands registered[^\n]*\n?/m, "\n")
       .gsub(/\$bot\.register_application_command\(/, 'slash_cmd.call(')
body = body.lines.map { |l| "    #{l}" }.join

header = <<~'RUBY'
  # frozen_string_literal: true

  # ==========================================
  # Blossom slash command SCHEMA for Discord bulk registration.
  # Command handlers remain in commands/** via $bot.application_command(...)
  #
  # Regenerate from slash_registry.rb (=begin block): ruby components/_gen_slash_definitions.rb
  # ==========================================

  module BlossomSlashDefinitions
    module_function

    # Builds the PUT /applications/{id}/commands payload (bulk overwrite).
    def global_application_commands
      cmds = []
      slash_cmd = proc do |name, description, type: :chat_input, default_member_permissions: nil, contexts: nil, nsfw: nil, &blk|
        t = Discordrb::ApplicationCommand::TYPES[type] || type
        b = Discordrb::Interactions::OptionBuilder.new
        blk&.call(b)
        row = {
          'name' => name.to_s,
          'description' => description.to_s,
          'type' => t.to_i,
          'options' => JSON.parse(JSON.generate(b.to_a))
        }
        row['default_member_permissions'] = default_member_permissions unless default_member_permissions.nil?
        row['contexts'] = contexts unless contexts.nil?
        row['nsfw'] = nsfw unless nsfw.nil?
        cmds << row
      end

RUBY

footer = <<~'RUBY'
    names = cmds.map { |c| c['name'] }
    dups = names.tally.reject { |_n, c| c == 1 }.keys
    raise "Duplicate slash command names: #{dups.join(',')}" if dups.any?

    cmds
  end
end
RUBY

File.write(File.join(__dir__, 'slash_definitions.rb'), header + body + footer)
puts 'Wrote slash_definitions.rb (%d bytes)' % File.size(File.join(__dir__, 'slash_definitions.rb'))
