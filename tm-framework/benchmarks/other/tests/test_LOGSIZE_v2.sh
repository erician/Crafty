#!/bin/bash

#############
# Compares the backward performance
#############

#sleep 1h

SAMPLES=10

# BANK parameters
NB_TRANSFERS=10000000
NB_TRANSFERS_READ=28000000
NB_TRANSFERS_WRIT=2800000
BANK_BUDGET=1000000
UPDATE_RATE="90" # TODO: this is not being used
THREADS="1 2 4 8 12 13 14 16 20 24 26 27 28"
TX_SIZE="2"
READ_SIZE="64"

LOG_SIZE="25000000 100000000 250000000"
FILTER="0.0075 0.01 0.03 0.06 0.125 0.25"

BUILD_SCRIPT=./build.sh
DATA_FOLDER_90_N=./dataLOGSIZE2_90_N
DATA_FOLDER_90_C=./dataLOGSIZE2_90_C
SCRIPTS_FOLDER=../../scripts
PLOT_FOLDER=./tests/plot

NB_ACCOUNTS=2048
NB_ACCOUNTS_L=8192
NB_ACCOUNTS_H=64

# dir where build.sh is
cd ..

mkdir -p $DATA_FOLDER_90_N
mkdir -p $DATA_FOLDER_90_C

### Call with 1-TX_SIZE 2-UPDATE_RATE 3-THREADS 4-NB_ACCOUNTS 5-NB_TRANSFERS
function run_bench_N {
	echo -ne "0\t0\t$4\t$2\t$1\t$READ_SIZE\n" >> parameters.txt
	ipcrm -M 0x00054321 >/dev/null
	timeout 10s ./bank/bank -a $4 -d $5 -b $BANK_BUDGET -u $2 -n $3 -s $1 -r $READ_SIZE -q >/dev/null
	# retry
	if [ $? -ne 0 ]; then
		timeout 1m ./bank/bank -a $4 -d $5 -b $BANK_BUDGET -u $2 -n $3 -s $1 -r $READ_SIZE -q >/dev/null
	fi
	if [ $? -ne 0 ]; then
		timeout 3m ./bank/bank -a $4 -d $5 -b $BANK_BUDGET -u $2 -n $3 -s $1 -r $READ_SIZE -q >/dev/null
	fi
}

function run_bench_C {
	echo -ne "0\t0\t$4\t$2\t$1\t$READ_SIZE\n" >> parameters.txt
	ipcrm -M 0x00054321 >/dev/null
	timeout 30s ./bank/bank -a $4 -d $5 -b $BANK_BUDGET -u $2 -n $3 -s $1 -r $READ_SIZE -q >/dev/null
	# retry
	if [ $? -ne 0 ]; then
		timeout 2m ./bank/bank -a $4 -d $5 -b $BANK_BUDGET -u $2 -n $3 -s $1 -r $READ_SIZE -q >/dev/null
	fi
	if [ $? -ne 0 ]; then
		timeout 5m ./bank/bank -a $4 -d $5 -b $BANK_BUDGET -u $2 -n $3 -s $1 -r $READ_SIZE -q >/dev/null
	fi
}

# TODO:
function bench {
	for i in `seq $SAMPLES`
	do
		# 10 - NO_CONTENTION
		# NB_ACCOUNTS=$NB_ACCOUNTS_L
		# NB_TRANSFERS=$NB_TRANSFERS_READ
		# rm -f parameters.txt stats_file stats_file.aux_thr
		# echo -ne "#SEQ\tNO_CONFL\tACCOUNTS\tUPDATE_RATE\tSIZE_TX\tREAD_SIZE\n" > parameters.txt
		# for j in $THREADS
		# do
		# 	run_bench_N $TX_SIZE 10 $j $NB_ACCOUNTS $NB_TRANSFERS
		# done
		# mv parameters.txt     $DATA_FOLDER_10_N/"$1"_par_s"$i"
		# mv stats_file         $DATA_FOLDER_10_N/"$1"_s"$i"
		# mv stats_file.aux_thr $DATA_FOLDER_10_N/"$1"_aux_s"$i"

		# 50 - NO_CONTENTION
		NB_ACCOUNTS=$NB_ACCOUNTS_L
		NB_TRANSFERS=$NB_TRANSFERS_WRIT
		rm -f parameters.txt stats_file stats_file.aux_thr
		echo -ne "#SEQ\tNO_CONFL\tACCOUNTS\tUPDATE_RATE\tSIZE_TX\tREAD_SIZE\n" > parameters.txt
		for j in $THREADS
		do
			run_bench_N $TX_SIZE 90 $j $NB_ACCOUNTS $NB_TRANSFERS
		done
		mv parameters.txt     $DATA_FOLDER_90_N/"$1"_par_s"$i"
		mv stats_file         $DATA_FOLDER_90_N/"$1"_s"$i"
		mv stats_file.aux_thr $DATA_FOLDER_90_N/"$1"_aux_s"$i"

		# 10 - CONTENTION
		# NB_ACCOUNTS=$NB_ACCOUNTS_H
		# NB_TRANSFERS=$NB_TRANSFERS_READ
		# rm -f parameters.txt stats_file stats_file.aux_thr
		# echo -ne "#SEQ\tNO_CONFL\tACCOUNTS\tUPDATE_RATE\tSIZE_TX\tREAD_SIZE\n" > parameters.txt
		# for j in $THREADS
		# do
		# 	run_bench_C $TX_SIZE 10 $j $NB_ACCOUNTS $NB_TRANSFERS
		# done
		# mv parameters.txt     $DATA_FOLDER_10_C/"$1"_par_s"$i"
		# mv stats_file         $DATA_FOLDER_10_C/"$1"_s"$i"
		# mv stats_file.aux_thr $DATA_FOLDER_10_C/"$1"_aux_s"$i"

		# 90 - CONTENTION
		NB_ACCOUNTS=$NB_ACCOUNTS_H
		NB_TRANSFERS=$NB_TRANSFERS_WRIT
		rm -f parameters.txt stats_file stats_file.aux_thr
		echo -ne "#SEQ\tNO_CONFL\tACCOUNTS\tUPDATE_RATE\tSIZE_TX\tREAD_SIZE\n" > parameters.txt
		for j in $THREADS
		do
			run_bench_C $TX_SIZE 90 $j $NB_ACCOUNTS $NB_TRANSFERS
		done
		mv parameters.txt     $DATA_FOLDER_90_C/"$1"_par_s"$i"
		mv stats_file         $DATA_FOLDER_90_C/"$1"_s"$i"
		mv stats_file.aux_thr $DATA_FOLDER_90_C/"$1"_aux_s"$i"
	done
}

for l in $LOG_SIZE
do
	#  echo "$l"
	#  MAKEFILE_ARGS="SOLUTION=4 DO_CHECKPOINT=5 LOG_SIZE=$l \
	#      SORT_ALG=5 FILTER=0.99 CACHE_ALIGN_POOL=1 NDEBUG=1" \
	#      $BUILD_SCRIPT htm-sgl-nvm file >/dev/null
	#  bench NVHTM_B_"$l"

# l=25000000
	MAKEFILE_ARGS="SOLUTION=4 DO_CHECKPOINT=5 LOG_SIZE=$l \
	SORT_ALG=5 FILTER=0.50 CACHE_ALIGN_POOL=1 NDEBUG=1" \
	$BUILD_SCRIPT htm-sgl-nvm file >/dev/null
	bench NVHTM_B_50_"$l"

	MAKEFILE_ARGS="SOLUTION=4 DO_CHECKPOINT=5 LOG_SIZE=$l \
	SORT_ALG=5 FILTER=0.50 DO_CHECK=1 CACHE_ALIGN_POOL=1 NDEBUG=1" \
	$BUILD_SCRIPT htm-sgl-nvm file >/dev/null
	bench NVHTM_B_50_N_"$l"

	# MAKEFILE_ARGS="SOLUTION=4 DO_CHECKPOINT=5 LOG_SIZE=$l \
	# SORT_ALG=4 CACHE_ALIGN_POOL=1 NDEBUG=1" \
	# $BUILD_SCRIPT htm-sgl-nvm file >/dev/null
	# bench NVHTM_F_"$l"
done

MAKEFILE_ARGS="SOLUTION=4 DO_CHECKPOINT=4 LOG_SIZE=1000000 \
SORT_ALG=5 FILTER=0.50 CACHE_ALIGN_POOL=1 NDEBUG=1" \
$BUILD_SCRIPT htm-sgl-nvm file >/dev/null
bench NVHTM_W
# # #
# MAKEFILE_ARGS="SOLUTION=1 DO_CHECKPOINT=4 LOG_SIZE=1000000 \
# SORT_ALG=5 FILTER=0.50 CACHE_ALIGN_POOL=1 NDEBUG=1" \
# $BUILD_SCRIPT htm-sgl-nvm file >/dev/null
# bench HTM
# # #
# #
# MAKEFILE_ARGS="PERSISTENT_TM=0 CACHE_ALIGN_POOL=1 NDEBUG=1" \
# $BUILD_SCRIPT stm-tinystm file >/dev/null
# bench STM
# # #
MAKEFILE_ARGS="PERSISTENT_TM=1 CACHE_ALIGN_POOL=1 NDEBUG=1" \
$BUILD_SCRIPT stm-tinystm file >/dev/null
bench PSTM
#
MAKEFILE_ARGS="SOLUTION=2 CACHE_ALIGN_POOL=1 NDEBUG=1" \
$BUILD_SCRIPT htm-sgl-nvm file >/dev/null
bench PHTM

# for f in $FILTER
# do
# 	echo "FILTER: $f"
# # l=25000000
# 	MAKEFILE_ARGS="SOLUTION=4 DO_CHECKPOINT=5 LOG_SIZE=$LOG_SIZE \
# 	SORT_ALG=5 FILTER=$f CACHE_ALIGN_POOL=1 NDEBUG=1" \
# 	$BUILD_SCRIPT htm-sgl-nvm file >/dev/null
# 	bench NVHTM_B_"$f"
# done

cd ./tests/
./test_proc_LOGSIZE.sh
