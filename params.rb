class AlgorithmParams
  attr_accessor :parVals, :multiPar

  def initialize(algPars, multiPar = ["min_sim", "min_train_performance"])
    @parVals={}
    @multiPar=multiPar
    algPars=algPars.split(';')
    algPars.each { |par|
      par=par.split('=')
      name=par[0]
      vals=par[1]
      if multiPar.include? name
        vals=vals.split('|')
        raise "Values must have three components" if vals.size != 3
        @parVals[name] = [vals[0].to_f]
        while @parVals[name].last + vals[2].to_f <= vals[1].to_f
          @parVals[name] << @parVals[name].last + vals[2].to_f
        end
      else
          @parVals[name]=vals
      end
    }
    @multiPar = @multiPar - (@multiPar - @parVals.keys)
    @parNames = @parVals.keys
  end

  def configs
     mv = []
     @multiPar.each { |par|
       if mv.size == 0 
         mv = @parVals[par].collect { |v| [v] }
       else
         mv2 = []
         mv.each { |inn|
           @parVals[par].each { |val|
             mv2 << inn + [ val ]
           }
         }
         mv = mv2
       end
    }
    mv2 = mv.collect { |tuple|
      @multiPar.inject({}) { |h, name|
        h[name] = tuple[@multiPar.index(name)]
        h
      }
    }
    mv2
    mv3 = mv2.collect { |hsh|
      (@parNames - @multiPar).inject(hsh) { |hsh,name|
        hsh[name] = @parVals[name]
        hsh
      }
    }
    mv3
  end
end

