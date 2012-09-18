=begin
  * Name: opentox-validation-client.rb
  * Description: A client application for grid search on parameters of lazar or other algorithms
  * Author: Andreas Maunz
  * Date: 09/2012
  * License: BSD
=end

require 'rubygems'
require 'opentox-ruby'

require 'optparse'
require './params.rb'
require './superhash.rb'

$mandatory_arguments = [ [ "v", "validation_uri" ], ["a", "algorithm_uri" ], ["d", "dataset_uri"], ["f", "prediction_feature"], ["p", "algorithm_params"], ["t", "tasks"] ]

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

optparse.parse! # What's left in ARGV is the list of non-opt args.
$mandatory_arguments.each { |arg|
  raise(OptionParser::MissingArgument, "Missing argument '#{arg[1]}'") if options[arg[1]].size == 0
}

# Parse algorithm params into ruby structures, exploding multi params
aps = AlgorithmParams.new options["algorithm_params"] # explode multiparams
algParArr = aps.configs # create all crosscombinations

# Main loop
tasks = []
gridParVals = []
gridMeasures=SuperHash.new
gridValidations=SuperHash.new

while algParArr.size>0 || tasks.size>0
  puts "Tasks: #{tasks.to_yaml}"
  puts "algPars: #{algParArr.to_yaml}"
  # Fill
  if tasks.size < options["tasks"].to_i
    curAlgPars = algParArr.shift
    if curAlgPars
      apsString = aps.multiPar.collect { |name|
        name + '=' + curAlgPars[name].to_s
      }.join(';') + ";" +
      (aps.parNames - aps.multiPar).collect { |name|
        name + '=' + curAlgPars[name].to_s
      }.join(';')
      payload = {}
      payload[:algorithm_uri] = options["algorithm_uri"]
      payload[:dataset_uri] = options["dataset_uri"]
      payload[:prediction_feature] = options["prediction_feature"]
      payload[:alg_params] = apsString
      tasks << OpenTox::RestClientWrapper.post(options["validation_uri"],payload,{},nil,false).to_s.chomp
      puts "Starting task with alg params '#{payload.inspect}'"
      gridParVals << aps.multiPar.collect { |name| curAlgPars[name].to_s }
    end
  end

  # Remove
  tasks.each_with_index { |task,idx|
    begin
      t = OpenTox::Task.find(task)
    rescue
    end
    measure = "novalue"
    if t
      if t.completed?
        validation = t.result_uri
        begin
          res=YAML::load(OpenTox::RestClientWrapper.get( validation + "/statistics",{:accept => "application/x-yaml"},nil))
        rescue
        end
        if res
          if res[OT.regressionStatistics]
            measure = res[OT.regressionStatistics][OT.rSquare]
          else
            measure = res[OT.classificationStatistics][OT.accuracy]
          end
        end
      elsif t.error?
        validation = "NA"
        measure = "NA"
      end
    end
    if measure != "novalue"
      accessString = gridParVals[idx].collect {|val| "['" + val.to_s + "']"}.join('')
      puts "Task with alg params '#{accessString}' has finished: '#{measure.to_s}', '#{validation.to_s}'"
      eval("gridMeasures" + accessString + "=measure.to_s")
      eval("gridValidations" + accessString + "=validation.to_s")
      tasks.delete_at(idx)
      gridParVals.delete_at(idx)
    end
    sleep(5)
  }

end

puts gridMeasures.to_yaml
puts gridValidations.to_yaml
File.open("gridMeasures_" + Time.now.strftime("%m-%d-%H%M%S") + ".yaml", "w") do |file|
  file.write gridMeasures.to_yaml
end
File.open("gridValidations_" + Time.now.strftime("%m-%d-%H%M%S") + ".yaml", "w") do |file|
  file.write gridValidations.to_yaml
end

