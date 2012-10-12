=begin
  * Name: subgraph_mining.rb
  * Description: A client application for calculating subgraph descriptors.
  * Author: Andreas Maunz
  * Date: 09/2012
  * License: BSD
=end

require 'rubygems'
require 'opentox-ruby'
require 'optparse'

$mandatory_arguments = [ ["a", "algorithm_uri" ], ["d", "dataset_uri"] ]
$optional_arguments = [ ["f", "min_frequency"], ["i","include"], ["v", "verbose"] ]
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
verbose=false
if options[:verbose] == "true"
  verbose=true
end
options.delete(:verbose)

options[:complete_entries] = "true"
if options[:include]
  included = options[:include].split(',')
  puts "included features: #{included.join(', ')}" if verbose
end

ds=OpenTox::Dataset.find(options[:dataset_uri])
algorithm_uri = options[:algorithm_uri]
options.delete(:algorithm_uri)


included.each { |title|
  features.each { |f_uri,v|
    if title == v[DC.title]
      puts "Feature '#{v[DC.title]}'" if verbose
      options[:prediction_feature] = f_uri
      puts options.to_yaml if verbose
      begin
        res_url = OpenTox::RestClientWrapper.post(algorithm_uri, options)
        puts res_url
      rescue => e
        puts "#{e.class}: #{e.message}"
        puts "Backtrace:\n\t#{e.backtrace.join("\n\t")}"
      end
    end
  }
}
