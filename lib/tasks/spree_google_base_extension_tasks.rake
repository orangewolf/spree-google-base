require 'net/ftp'

namespace :spree_google_base do
  task :generate_and_transfer => [:environment] do |t, args|
    SpreeGoogleBase::FeedBuilder.generate_and_transfer
  end

  desc "Generate test product feed file in specified format. Formats: xml, tab separated txt"
  task :generate_test_file, [:format] => [:environment] do |t, args|
    raise 'Invalid format specified! Supported formats: xml, txt.' unless args[:format] == 'txt' or args[:format] == 'xml'
    puts "Dumping product catalog as #{args[:format]}."
    file_path = SpreeGoogleBase::FeedBuilder.generate_test_file("google_base_products.#{args[:format]}")
    puts "Finished dumping product catalog as #{args[:format]}. See it at [#{file_path}]."
  end
end
