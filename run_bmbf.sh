# Name: run_bmbf.sh
# Description: A wrapper for calculating subgraph descriptors from BMBF data.
# Author: Andreas Maunz
# Date: 10/2012
# License: BSD

. /home/am/install/ot-tools-user.sh
otconfig
otstart 
lh="http://localhost"

function get_result { 
  task=$1 
  while [ 1 ]; do 
    result=`curl -H "accept:text/uri-list" $task 2>/dev/null` 
    [ $result == $task ] && sleep 1 || break 
  done 
  echo $result 
}

function run_mining {
  alg=$1
  destdir="$2-`date +%Y-%m-%d-%H-%M-%S`"; mkdir "$destdir" 2>/dev/null
  for idx in `seq 2 5`; do
    ds='$'"disc$idx"
    eval ds=$ds 
    res_ds_list=""
    ruby subgraph_mining.rb -a http://localhost:8080/algorithm/fminer/$alg -d "$ds" -i "$assays" -f 100pm > dslist
    exec 0<dslist
    assay_idx=1
    while read res_ds; do 
      assay=`echo $assays | cut -d',' -f$assay_idx`
      csv_outfile="$destdir/${alg}_${assay}_${idx}.csv"
      curl -H 'accept:text/csv' "$res_ds" 2>/dev/null > "$csv_outfile"
      res_nr=`cat "$csv_outfile" | head -1 | sed 's/[^,]//g' | wc -c`
      echo "$assay, $res_ds, $res_nr"
      if [ -z "$res_ds_list" ]; then
        res_ds_list="$res_ds"
      else
        res_ds_list="$res_ds_list;$res_ds"
      fi
      assay_idx=$((assay_idx+1))
    done
    echo
    run_matching
    echo
  done
}

function run_matching {
    ruby smarts_matching.rb -d "$ds" -f "$res_ds_list" -o "$destdir/${alg}_${idx}_match.csv"
}


#  first insert SMILES structure information for Neustoff
# upload
for idx in `seq 2 5`; do
  task=`curl -X POST -F "file=@BMBF-abs_q_BMBF_Subset_28d90d_oral_inhal_disc$idx.csv;type=text/csv" $lh:8080/dataset 2>/dev/null`
  eval "disc$idx=`get_result $task`"
done
echo "2: $disc2, 3: $disc3, 4: $disc4, 5: $disc5" 
echo

# select assays with 10% non-missing values
# liver , 0.611 
# clinical.chemistry , 0.567
# body.weight , 0.532
# kidney , 0.442
# RBC , 0.351
# CNS , 0.296
# WBC , 0.204
# spleen , 0.201
# urine.analysis , 0.180
# male.reproductive.organ , 0.165
# adrenal.gland , 0.135
# thymus , 0.131
# heart , 0.102
# brain , 0.082
assays="liver,clinical_chemistry,body_weight,kidney,RBC,CNS,WBC,spleen,urine_analysis,male_reproductive_organ,thymus,heart,brain"
#assays="adrenal_gland"

run_mining bbrc csv_out
run_mining last csv_out
