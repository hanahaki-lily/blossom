# ==========================================
# SYSTEM: Module Loader (Refined)
# ==========================================

def load_blossom_modules
  puts "\n[SYSTEM] Booting Blossom Modules..."

  # Define the order of importance
  load_paths = [
    '../data/database', # Load DB first!
    '../helpers',
    '../components',
    '../commands',
    '../events'
  ]

  load_paths.each do |folder|
    path = File.expand_path(File.join(__dir__, folder))
    Dir.glob("#{path}/**/*.rb").each do |file|
      begin
        # Use require instead of eval for proper Ruby scoping
        require file
        puts "✅ Loaded: #{File.basename(file)}"
      rescue LoadError => e
        puts "❌ FAILED TO LOAD: #{file} - #{e.message}"
      end
    end
  end
end