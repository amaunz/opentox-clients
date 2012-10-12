# Name: run_bmbf.sh
# Description: A wrapper for calculating subgraph descriptors from  BMBF data.
# Author: Andreas Maunz
# Date: 10/2012
# License: BSD

otconfig
otstart 
lh="http://localhost"

# util function 
function get_result { 
  task=$1 
  while [ 1 ]; do 
    result=`curl -H "accept:text/uri-list" $task 2>/dev/null` 
    [ $result == $task ] && sleep 1 || break 
  done 
  echo $result 
}

function run_sgm {
  alg=$1
  for idx in `seq 2 5`; do
    ds='$'"disc$idx"
    eval ds=$ds 
    res_ds_list=""
    ruby subgraph_mining.rb -a http://localhost:8080/algorithm/fminer/$alg -d "$ds" -i "$assays" -f 100pm > dslist
    exec 0<dslist
    while read res_ds; do 
      res_nr=`curl -H 'accept:text/csv' $res_ds 2>/dev/null | head -1 | sed 's/[^,]//g' | wc -c`
      echo "$res_ds: $res_nr"
      res_ds_list="$res_ds_list,$res_ds"
    done
    echo "List: $res_ds_list"
    echo
  done
}


#  first insert SMILES structure information for Neustoff

# upload
for idx in `seq 2 5`; do
  echo $idx
  task=`curl -X POST -F "file=@BMBF-abs_q_BMBF_Subset_28d90d_oral_inhal_disc$idx.csv;type=text/csv" $lh:8080/dataset 2>/dev/null`
  eval "disc$idx=`get_result $task`"
done
echo "$disc2"
echo "$disc3"
echo "$disc4"
echo "$disc5" 

# select assays with 10% non-missing values
assays="body_weight,liver,kidney,clinical_chemistry,RBC,CNS,male_reproductive_organ,WBC,spleen,urine_analysis,thymus,brain,heart"

run_sgm bbrc
run_sgm last

