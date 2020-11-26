#!/bin/bash

start=$(date)
BEGIN=$(date +%s)
HOST=$(hostname)

RUNdir="${PROJECTdir}/testcases/swash/testcases/northshore"
RUNlog="${PROJECTdir}/testcases/swash/testcases/northshore/runlog.log"
DATAdir="${PROJECTdir}/testcases/swash/testcases/northshore/data"
INPUTtemp="${PROJECTdir}/testcases/swash/testcases/northshore/template/INPUT_temp"
SWASHexe="${PROJECTdir}/lib64/swash/bin/swash-mpi.exe"
mpiexe="${PROJECTdir}/lib64/mpich/bin/mpiexec"
timeseriesx="${PROJECTdir}/testcases/swash/testcases/northshore/template/timeseries.py"
python="${PROJECTdir}/lib64/anaconda3/bin/python"

cd ${RUNdir}

echo "-----------------------------------------------------" > ${RUNlog}
echo "TESTCASE BEGINS: $start                     Host:$HOST" >> ${RUNlog}
echo "-----------------------------------------------------" >> ${RUNlog}

echo " " >> ${RUNlog}
echo "SWASH TESTCASE RUNNING" >> ${RUNlog}
echo " " >> ${RUNlog}

# Clean old files
rm ${DATAdir}/finalData* ${DATAdir}/runsum*txt ${DATAdir}/*tab*

# Model CGRID SPECs: 10m, 8x6m, 5m:
CGRID_sevenm="CGRID 8841.0 7339.0 40.0 12105 9005 1515 1501"
CGRID_tenm="CGRID 8841.0 7339.0 40.0 12105 9005 1210 900"
CGRID_fivem="CGRID 8841.0 7339.0 40.0 12105 9005 2420 1800"

# Boundary Conditions:
SWHT=2
Tp=18
step=3600

# iterate through sensitivity simulations: 
for i in 0.035 0.07 0.10 0.25 
do
	# change back to working dir
	cd ${RUNdir}
        FRICTION="${i}"
         
        for i in 10 7 5
	do
   		if [ ${i} == "10" ]
		then
			RESOLUTION=10
		fi
		if [ ${i} == "7" ]
                then
                        RESOLUTION=7
                fi
		if [ ${i} == "5" ]
                then
                        RESOLUTION=5
                fi

                        for i in 2   
			do
				RUNTIME=${i}

                                for i in 0.26 0.775
				do
					# change back to working dir
                                        cd ${RUNdir}
					WLEV=${i}
					echo "${SWHT} ${Tp} ${FRICTION} ${WLEV} ${RUNTIME} ${RESOLUTION}" >> ${RUNlog}
 
				        # Clean Tab Files from previous runs
					rm PRINT* 
					rm Err*
                                        rm *tab*

					# Prep INPUT File for simulation
					sed -e "s/###FRIKNOB###/${FRICTION}/g" ${INPUTtemp} > ${RUNdir}/INPUT
        				sed -i "s/###SWHT###/${SWHT}/g" INPUT
        				sed -i "s/###Tp###/${Tp}/g" INPUT
					sed -i "s/###WLEV###/${WLEV}/g" INPUT
					sed -i "s/###HR###/${RUNTIME}/g" INPUT

                                        if [ ${RESOLUTION} == "10" ]
                   			then
                        			sed -i "s/###CGRID###/${CGRID_tenm}/g" INPUT
                			fi
					if [ ${RESOLUTION} == "7" ]
                                        then
                                                sed -i "s/###CGRID###/${CGRID_sevenm}/g" INPUT
                                        fi
					if [ ${RESOLUTION} == "5" ]
                                        then
                                                sed -i "s/###CGRID###/${CGRID_fivem}/g" INPUT
                                        fi
	
					# EXECUTE SIMULATION
                       			${mpiexe} -n 48 ${SWASHexe}

                                        # POST PROCESS DATA
					cp PRINT-001 ${DATAdir}/PRINT_${SWHT}_${Tp}_${FRICTION}_${WLEV}_${RUNTIME}_${RESOLUTION}
					
					# ENSURE THE RUN FINISHED AND THE REQUIRED FILES EXISTS
                                        if [ -f "2m.tab" ] && [ "2msun.tab" ] && [ "vland.tab" ]  
					then
  					  	echo "Data files exist and run finished as designed." >> ${RUNlog} 
						RPTAB=`tail -n1 ${RUNdir}/2m.tab | awk '{print $1}' | cut -c 1-4`	
						SUNTAB=`tail -n1 ${RUNdir}/2msun.tab | awk '{print $1}' | cut -c 1-4`
                                        	VLANDTAB=`tail -n1 ${RUNdir}/vland.tab | awk '{print $1}' | cut -c 1-4`

						# make a backup of files
						cp ${RUNdir}/2m.tab ${DATAdir}/2m.tab_${SWHT}_${Tp}_${FRICTION}_${WLEV}_${RUNTIME}_${RESOLUTION}
                                                cp ${RUNdir}/2msun.tab ${DATAdir}/2msun.tab_${SWHT}_${Tp}_${FRICTION}_${WLEV}_${RUNTIME}_${RESOLUTION}
					        cp ${RUNdir}/vland.tab ${DATAdir}/vland.tab_${SWHT}_${Tp}_${FRICTION}_${WLEV}_${RUNTIME}_${RESOLUTION}	
					else
						echo "Data files don't exist - check for backup raw files" >> ${RUNlog}
						twometertab=`find -L 2m.tab* -type f ! -size 0`
                                        	twometersuntab=`find -L 2msun.tab* -type f ! -size 0`
						twometervland=`find -L vland.tab* -type f ! -size 0`

                                                # Rename files
                                                mv ${twometertab} 2m.tab
						mv ${twometersuntab} 2msun.tab
						mv ${twometervland} vland.tab

						RPTAB=`tail -n1 ${RUNdir}/2m.tab | awk '{print $1}' | cut -c 1-4`
                                                SUNTAB=`tail -n1 ${RUNdir}/2msun.tab | awk '{print $1}' | cut -c 1-4`
                                                VLANDTAB=`tail -n1 ${RUNdir}/vland.tab | awk '{print $1}' | cut -c 1-4` 
						
						# make a backup of files
                                                cp ${RUNdir}/2m.tab ${DATAdir}/2m.tab_${SWHT}_${Tp}_${FRICTION}_${WLEV}_${RUNTIME}_${RESOLUTION}
                                                cp ${RUNdir}/2msun.tab ${DATAdir}/2msun.tab_${SWHT}_${Tp}_${FRICTION}_${WLEV}_${RUNTIME}_${RESOLUTION}
                                                cp ${RUNdir}/vland.tab ${DATAdir}/vland.tab_${SWHT}_${Tp}_${FRICTION}_${WLEV}_${RUNTIME}_${RESOLUTION}
                                        fi

					# One last check - abort if there are no files and investigate issues
					if [ -f "2m.tab" ] && [ "2msun.tab" ] && [ "vland.tab" ]
                                        then
						echo "Final Data Check Test - Data files exist." >> ${RUNlog}
					else
						echo "Final Data Check test - Data files don't exist - something went wrong - aborting." >> ${RUNlog}
						exit
					fi

					SECONDS=$((${RUNTIME} * ${step}))

                                        #if [ ${RPTAB} == ${SECONDS} ] && [ ${SUNTAB} == ${SECONDS} ] && [ ${VLANDTAB} == ${SECONDS} ] 
					#then
					# ARCHIVE THE DATA
					cp ${RUNdir}/2m.tab ${DATAdir}
                                        cp ${RUNdir}/2msun.tab ${DATAdir}
                                        cp ${RUNdir}/vland.tab ${DATAdir}

					if [ ${RPTAB} -lt 5000 ] 
					then
					 	sed -i '1,1807d' ${DATAdir}/*tab
					else
						sed -i '1,3607d' ${DATAdir}/*tab
					fi

					cd ${DATAdir}         
            				
					for i in 2m 2msun vland
					do
						# Copy over timeseries script template and process Data:
						sed -e "s/###datafile###/${i}/g" ${timeseriesx} > ${DATAdir}/timeseries.py    
					
                                               	# Crunch 2% SETUP Hss Hig values
						${python} timeseries.py
						python timeseries.py
						runsum=`cat runsum_${i}.txt` 
						echo "${SWHT} ${Tp} ${FRICTION} ${WLEV}  ${RUNTIME}  ${RESOLUTION}  ${runsum}" >> finalData_${i}
					done
					# change back to working dir
					cd ${RUNdir}
                                       #  else
				       #         echo "Run didn't finish - Final time step didn't match run time. " >> ${RUNlog}
				       #		cd ${RUNdir}							
				#	fi
                                done
                        done	 
        done
done
