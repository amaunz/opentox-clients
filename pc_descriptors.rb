=begin
  * Name: pc_descriptors.rb
  * Description: A client application for calculating PC descriptors
  * Author: Andreas Maunz
  * Date: 09/2012
  * License: BSD
=end

require 'rubygems'
require 'opentox-ruby'
require 'optparse'

$mandatory_arguments = [ ["a", "algorithm_uri" ], ["d", "dataset_uri"] ]
$optional_arguments = [ ["p", "pc_type"], ["l", "lib"] ]
$arguments = $mandatory_arguments + $optional_arguments

options = {}
optparse = OptionParser.new do |opts|
  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
  $arguments.each { |arg|
    options[arg[1]] = ""
    opts.on( "-#{arg[0]}", "--#{arg[1]} MAND", "Mandatory argument" ) { |f|
      options[arg[1]] = f
    }
  }
end

optparse.parse! # What's left in ARGV is the list of non-opt args.
$mandatory_arguments.each { |arg|
  raise(OptionParser::MissingArgument, "Missing argument '#{arg[1]}'") if options[arg[1]].size == 0
}
puts options.to_yaml
$optional_arguments.each { |s,l| options.delete(l) if options[l]=="" }
options = Hash[options.map{ |k, v| [k.to_sym, v] }]
puts options.to_yaml
algorithm_uri = options[:algorithm_uri]
options.delete(:algorithm_uri)

begin
  res_url = OpenTox::RestClientWrapper.post(algorithm_uri, options)
  puts res_url
rescue => e
  puts "#{e.class}: #{e.message}"
  puts "Backtrace:\n\t#{e.backtrace.join("\n\t")}"
end

