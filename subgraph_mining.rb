=begin
  * Name: subgraph_mining.rb
  * Description: A client application for calculating subgraph descriptors. Assumes cmpdfix.
  * Author: Andreas Maunz
  * Date: 09/2012
  * License: BSD
=end

require 'rubygems'
require 'opentox-ruby'
require 'optparse'

$mandatory_arguments = [ ["a", "algorithm_uri" ], ["d", "dataset_uri"] ]
$optional_arguments = [ ["f", "min_frequency"] ]
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
$optional_arguments.each { |s,l| options.delete(l) if options[l]=="" }
options = Hash[options.map{ |k, v| [k.to_sym, v] }]
options[:complete_entries] = "true"

ds=OpenTox::Dataset.find(options[:dataset_uri])
idx=0
algorithm_uri = options[:algorithm_uri]
options.delete(:algorithm_uri)

ds.features.each { |f_uri,v|
  options[:prediction_feature] = f_uri
  idx+=1
  puts "Feature '#{v[DC.title]}' (#{idx}/#{ds.features.size})"
  puts options.to_yaml
  begin
    res_url = OpenTox::RestClientWrapper.post(algorithm_uri, options)
    puts res_url
    puts
  rescue => e
    puts "#{e.class}: #{e.message}"
    puts "Backtrace:\n\t#{e.backtrace.join("\n\t")}"
  end
}
