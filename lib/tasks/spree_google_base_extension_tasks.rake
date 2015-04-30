require 'net/ftp'

namespace :spree_google_base do
  desc "Generate and transfer product feed in specified format. Formats: xml, txt"
  task :generate_and_transfer, [:format] => [:environment] do |t, args|
    args.with_defaults(format: 'xml')
    raise 'Invalid format specified! Supported formats: xml, txt.' unless %w[txt xml].include? args[:format]
    SpreeGoogleBase::FeedBuilder.generate_and_transfer(args[:format])
    puts "Product catalog sent."
  end

  desc "Generate test product feed file in specified format. Formats: xml, txt"
  task :generate_test_file, [:format] => [:environment] do |t, args|
    args.with_defaults(format: 'xml')
    raise 'Invalid format specified! Supported formats: xml, txt.' unless %w[txt xml].include? args[:format]
    puts "Dumping product catalog as #{args[:format]}."
    file_path = SpreeGoogleBase::FeedBuilder.generate_test_file(args[:format])
    puts "Finished dumping product catalog as #{args[:format]}. See it at [#{file_path}]."
  end
end
