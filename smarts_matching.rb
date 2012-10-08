=begin
  * Name: smarts_matching.rb
  * Description: A client application for matching smarts.
  * Author: Andreas Maunz
  * Date: 10/2012
  * License: BSD
=end

require 'rubygems'
require 'opentox-ruby'
require 'optparse'
require '/home/ot1/opentox-ruby/www/opentox/algorithm/last-utils/lu.rb'

$mandatory_arguments = [ ["d", "dataset_uri"], ["f", "feature_dataset_uris"] ]
$optional_arguments = [ ]
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
options[:nr_hits] = "true"

ds=OpenTox::Dataset.find(options[:dataset_uri])
compounds=ds.compounds.collect { |cmpd|
  OpenTox::Compound.new(cmpd).to_smiles
}

csv_out = [["ID"]]
csv_out += (1..compounds.size).to_a.collect { |idx| [ idx ] }

fds_uris=options[:feature_dataset_uris].split(';')
fds_uris.each { |fds_uri|
  puts fds_uri
  smartss = []
  fds.features.keys.collect { |f_uri| 
      feat=OpenTox::Feature.find(f_uri)
      smarts = feat.metadata[OT.smarts]
      if smarts
        csv_out[0] << "\"#{smarts}\""
      end
      smartss << smarts
  }

  fds=OpenTox::Dataset.find(fds_uri)
  compounds.each_with_index { |smi,idx|
    smartss.each { |smarts| 
      hits=lu.match(smi,smarts,false,true) 
      csv_out[idx+1] << hits
    }
  }
}
puts

puts csv_out.collect { |row| row.join(',') }.join("\n")
