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
  minfreq=$2
  for idx in `seq 2 5`; do
    ds='$'"disc$idx"
    eval ds=$ds 
    res_ds_list=""
    ruby subgraph_mining.rb -a http://localhost:8080/algorithm/fminer/$alg -d "$ds" -i "$assays" -f "$minfreq" > dslist
    exec 0<dslist
    assay_idx=1
    while read res_ds; do 
      assay=`echo $assays | cut -d',' -f$assay_idx`
      csv_outfile="$destdir/${alg}_${assay}_${idx}.csv"
      if [ -n "$res_ds" ]; then
        curl -H 'accept:text/csv' "$res_ds" 2>/dev/null > "$csv_outfile"
      else
        touch "$csv_outfile"
      fi
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

function run_pc {
    csv_outfile="$destdir/pc.csv"
    res_ds=`ruby pc_descriptors.rb -d "$disc2" -a "$lh:8080/algorithm/pc/AllDescriptors"`
    curl -H 'accept:text/csv' "$res_ds" 2>/dev/null > "$csv_outfile"
}


#  first insert SMILES structure information for Neustoff
# upload
for idx in `seq 2 5`; do
  task=`curl -X POST -F "file=@BMBF-abs_q_BMBF_Subset_28d90d_oral_inhal_disc$idx.csv;type=text/csv" $lh:8080/dataset 2>/dev/null`
  eval "disc$idx=`get_result $task`"
done
echo "2: $disc2, 3: $disc3, 4: $disc4, 5: $disc5" 
echo


#destdir="csv_out-`date +%Y-%m-%d-%H-%M-%S`"; mkdir "$destdir" 2>/dev/null
#run_pc

# select assays with 20% non-missing values

#removed=a_2u_nephropathy,male_accessory_gland,bone,gall_bladder_bile_duct,urine_analysis,pituitary_gland__hypohysis_,pancreas

assays="adrenal_gland,bladder,body_weight,bone_marrow,brain,clinical_chemistry,CNS,female_reproductive_organ,haematopoiesis,heart,intestine,kidney,liver,lymph_node,male_reproductive_organ,RBC,spleen,thymus,thyroid_gland,WBC"
destdir="csv_out-`date +%Y-%m-%d-%H-%M-%S`"; mkdir "$destdir" 2>/dev/null
run_mining bbrc 70pm
run_mining last 70pm
