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

  loaded = []
  failed = []

  load_paths.each do |folder|
    path = File.expand_path(File.join(__dir__, folder))
    Dir.glob("#{path}/**/*.rb").each do |file|
      begin
        require file
        puts "✅ Loaded: #{File.basename(file)}"
        loaded << File.basename(file)
      rescue => e
        puts "❌ FAILED TO LOAD: #{File.basename(file)} - #{e.class}: #{e.message}"
        failed << "#{File.basename(file)}: #{e.class}: #{e.message}"
      end
    end
  end

  puts "\n📋 Boot complete: #{loaded.size} loaded, #{failed.size} failed"
end
