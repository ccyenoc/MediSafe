require 'xcodeproj'
project_path = 'ios/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)
project.targets.each do |target|
  puts "Target: #{target.name}"
  target.build_configurations.each do |config|
    puts "  Config: #{config.name}"
    puts "    OTHER_CFLAGS: #{config.build_settings['OTHER_CFLAGS']}"
    puts "    OTHER_LDFLAGS: #{config.build_settings['OTHER_LDFLAGS']}"
  end
end
