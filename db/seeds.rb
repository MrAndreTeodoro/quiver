# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create or update the default profile from seed file
profile_seed_path = Rails.root.join("db", "profile_seed.md")

if File.exist?(profile_seed_path)
  profile_content = File.read(profile_seed_path)

  Profile.find_or_create_by(name: "André Teodoro") do |p|
    p.content = profile_content
  end

  # If profile exists but content is empty, update it
  profile = Profile.find_by(name: "André Teodoro")
  if profile && profile.content.blank?
    profile.update!(content: profile_content)
  end

  puts "✓ Profile 'André Teodoro' seeded successfully"
else
  puts "⚠ Profile seed file not found at #{profile_seed_path}"

  # Create empty profile if no seed file
  Profile.find_or_create_by(name: "Default User") do |p|
    p.content = "# Your Name\n\n## Professional Summary\n\nAdd your professional summary here..."
  end

  puts "✓ Empty profile 'Default User' created (please edit in the UI)"
end

puts "✓ Database seeding complete"
