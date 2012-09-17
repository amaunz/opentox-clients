require 'rubygems'
require 'opentox-ruby'

require 'optparse'
require './params.rb'

$mandatory_arguments = [ ["a", "algorithm_uri" ], ["d", "dataset_uri"], ["f", "prediction_feature"], ["p", "algorithm_params"] ]

options = {}
optparse = OptionParser.new do|opts|
  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
  $mandatory_arguments.each { |arg|
    options[arg[1]] = ""
    opts.on( "-#{arg[0]}", "--#{arg[1]} MAND", "Mandatory argument" ) { |f|
      options[arg[1]] = f
    }
  }
end

# What's left is the list of non-opt args.
optparse.parse!

# Check for presence of arguments
$mandatory_arguments.each { |arg|
  raise(OptionParser::MissingArgument, "Missing argument '#{arg[1]}'") if options[arg[1]].size == 0
}

# Parse user input into ruby structures
aps = AlgorithmParams.new options["algorithm_params"]
#puts aps.parVals.to_yaml
mv = aps.configs
#puts mv.to_yaml



