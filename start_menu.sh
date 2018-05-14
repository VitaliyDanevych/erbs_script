#!/bin/bash

echo "start!"
wdir=$(pwd -P)
echo "your working directory is: " $wdir

#today=$(date '+DATE: %d_%m_%Y' | sed 's/DATE: //')

show_menu(){
    NORMAL=`echo "\033[m"`
    MENU=`echo "\033[36m"` #Blue
    NUMBER=`echo "\033[33m"` #yellow
    FGRED=`echo "\033[41m"`
    RED_TEXT=`echo "\033[31m"`
    ENTER_LINE=`echo "\033[33m"`
    echo -e "${MENU}*********************************************${NORMAL}"
    echo -e "${MENU}**${NUMBER} 1)${MENU} Step 1: Chose target subnet name for ERBS migration ${NORMAL}"
    echo -e "${MENU}**${NUMBER} 2)${MENU} Step 2: Prepare files and make backups ${NORMAL}"
    echo -e "${MENU}**${NUMBER} 3)${MENU} Step 3: Apply ERBS sites deletion in OSS ${NORMAL}"
    echo -e "${MENU}**${NUMBER} 4)${MENU} Step 4: Apply ERBS sites creation into subnet in OSS ${NORMAL}"
    echo -e "${MENU}**${NUMBER} 5)${MENU} Step 5: Show readme.txt file ${NORMAL}"
    echo -e "${MENU}**${NUMBER} 6)${MENU} Step 6: Quit ${NORMAL}"
    echo -e "${MENU}*********************************************${NORMAL}"
    echo -e "${ENTER_LINE}Please enter a menu option or press for exit ${RED_TEXT}Ctl+C ${NORMAL}"
    #read opt
}


PS3='Please enter your choice: '
options=("Step 1: Chose target subnet name for ERBS migration" "Step 2: Prepare files and make backups" "Step 3: Apply ERBS sites deletion in OSS" "Step 4: Apply ERBS sites creation into subnet in OSS" "Step 5: Show readme.txt file" "Step 6: Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Step 1: Chose target subnet name for ERBS migration")
            echo "you have the following list of BSC on OSS-RC1:"
            cat ${wdir}/eNM_regions.txt
            echo "Choose one of the mentioned eNB regions - just type it and press Enter"
            read eNB_name
            echo 'It was choosen: ' $eNB_name 'Ok. Go to the next step!'
            show_menu
            ;;
        "Step 2: Prepare files and make backups")
            echo "you have choosen Step 2"
            if [ -z "$eNB_name" ]; then echo "You have not choosen eNB region at Step 1. Go to the Step 1 first and return to Step 2 after that"; break; fi
            
            echo "checking if it is exist the site_list.txt file with list of sites for processing.."
            if ! [ -f ${wdir}/site_list.txt ]
                then
                    echo "The site_list.txt file doesn't exist. Please, put that file to the working directory! " "$wdir".
                else
                    echo "The site_list.txt file has been found."
                    echo -e "${ENTER_LINE}The file has ${MENU} $(cat ${wdir}/site_list.txt | wc -l) ${ENTER_LINE} lines: ERBS elements ${NORMAL}"
                    echo "${ENTER_LINE}Do you wish to continue with mentioned quatity of ERBS sites?, ${RED_TEXT} press (y/n)? ${NORMAL}"
                    read answer
                    if [ "$answer" != "${answer#[Yy]}" ] ;then
                       echo "Your choice is Yes. The script will do more.."
                       echo "${ENTER_LINE}Do you wish to see the list of mentioned ERBS sites or just to start continuue?, ${RED_TEXT} press (y/n)? ${NORMAL}"
                       read answer
                        if [ "$answer" != "${answer#[Yy]}" ] ;then
                           echo "Your choice is Yes. The list of ERBS sites: "
                           cat ${wdir}/site_list.txt
                        else
                            echo "Your choice is No. The program will continue..."
                        fi
                    else
                        echo "Your choice is No. Check the ${wdir}/site_list.txt first. Exiting from progrom..."
                        break
                    fi
                    
                    echo "${ENTER_LINE}Do you wish to continue?, ${RED_TEXT} press (y/n)? ${NORMAL}"
                    read answer
                    if [ "$answer" != "${answer#[Yy]}" ] ;then
                       echo "Your choice is Yes. The script will continue.."
                    else
                        echo "Your choice is No. Exiting from progrom..."
                        break
                    fi
            fi
            
            echo "Make backups..."
            cd ${wdir}
            rm -rf temporary/*.xml
            rm -rf temporary/*.txt
            cp -p *.xml temporary/
            cp -p *.txt temporary/
            tar czvf backups/backup_${eNB_name}_$(date '+DATE: %d_%m_%Y_%H_%m' | sed 's/DATE: //').tar.gz temporary/
            cd ${wdir}
            rm -rf ERBS*.xml RadioNode*.xml to_delete.xml to_create.xml
            echo -e "${ENTER_LINE}Backups are made. ${NORMAL}"
            
            echo "checking if it is exist export of whole network topology XML file with today date.."
            if ! [ -f ${wdir}/exported_whole_network_$(date '+DATE: %d_%m_%Y' | sed 's/DATE: //').xml ]
                then
                    echo "The file is not exists, Create it!"
                    echo "Exporting of whole network to xml file...".
                    echo "it takes a few minutes. you could drink a cup of cofee while it is proccessing :) ...."
                    cd ${wdir}/
                    /opt/ericsson/arne/bin/export.sh -f exported_whole_network_$(date '+DATE: %d_%m_%Y' | sed 's/DATE: //').xml -o > /dev/null 2>&1
                    echo "The whole network topology XML file : " "${wdir}/exported_whole_network_$today.xml " " has been created."
                else
                    echo "The file ${wdir}/exported_whole_network_$(date '+DATE: %d_%m_%Y' | sed 's/DATE: //').xml exists. I will not create a new one."
            fi
            
            echo "making export of all RadioNode elements to one XML file..."
            cd ${wdir}/
            /opt/ericsson/arne/modeltrans/bin/searchManagedElementByPrimaryType.sh exported_whole_network_$(date '+DATE: %d_%m_%Y' | sed 's/DATE: //').xml RadioNode RadioNode_$(date '+DATE: %d_%m_%Y' | sed 's/DATE: //').xml
            echo -e "${ENTER_LINE}The all OSS-RC RadioNode elements have been exported to the file : ${MENU} ${wdir}/RadioNode_$(date '+DATE: %d_%m_%Y' | sed 's/DATE: //').xml ${NORMAL}"
              
            #"making one line of sites separated by special symbols (comma, without spaces)..."
            my_line=$(cat site_list.txt | sed '/^$/d' | dos2unix | sed 's/^[ \t]*//;s/[ \t]*$//' | perl -pi -e 's/\n/,/g;' | perl -pi -e 's/\,$/\n/g;')
            echo 'my_line: ' "$my_line"
            
            
            #Making export of selected ERBS sites
            cd ${wdir}/
            /opt/ericsson/arne/modeltrans/bin/searchManagedElementById.sh RadioNode_$(date '+DATE: %d_%m_%Y' | sed 's/DATE: //').xml "$my_line" ERBS_selected_$(date '+DATE: %d_%m_%Y' | sed 's/DATE: //').xml
            echo -e "${ENTER_LINE}The required quatity ERBS sites (controled by site_list.txt) exported to the XML file: ${MENU}  ${wdir}/ERBS_selected_$(date '+DATE: %d_%m_%Y' | sed 's/DATE: //').xml ${NORMAL}"
            
            #Insert neccessary lines (4 from the beginning and 3 from the end of file)
            echo 'eNB_name: ' "$eNB_name"
            gawk 'NR==5{1;print "<SubNetwork userLabel=\"'$eNB_name'\" networkType=\"SiteSolutions\">"}1' ERBS_selected_$(date '+DATE: %d_%m_%Y' | sed 's/DATE: //').xml > ERBS_selected_$(date '+DATE: %d_%m_%Y' | sed 's/DATE: //')_mod.xml
            end_line=$(cat ERBS_selected_$(date '+DATE: %d_%m_%Y' | sed 's/DATE: //')_mod.xml | wc -l)
            count=$(expr $end_line - 1)  #the count of insert line from the end of file
            echo 'count: ' "$count"
            gawk 'NR=='$count'{1;print "</SubNetwork>"}1' ERBS_selected_$(date '+DATE: %d_%m_%Y' | sed 's/DATE: //')_mod.xml > ERBS_selected_$(date '+DATE: %d_%m_%Y' | sed 's/DATE: //')_mod2.xml
            #echo -e "${ENTER_LINE}The ${wdir}/ERBS_selected_$(date '+DATE: %d_%m_%Y' | sed 's/DATE: //')_mod2.xml file has been created with ${MENU}target eNB_name ${eNB_name}"
            cd ${wdir}/
            mv ERBS_selected_$(date '+DATE: %d_%m_%Y' | sed 's/DATE: //')_mod2.xml to_create.xml
            echo -e "${ENTER_LINE}The subnetwork tags were added to the ${wdir}/to_create.xml file with target eNB_name ${MENU} ${eNB_name} ${NORMAL}"
            
            #To make XML for deletion of ERBS sites
            python eric_to_delete_xml_file.py
            echo -e "${ENTER_LINE}The file ${MENU} ${wdir}/to_delete.xml ${ENTER_LINE} has been created"
            echo -e "${ENTER_LINE}Step 2 is finished. Go to the next step!"
            show_menu
            ;;
        "Step 3: Apply ERBS sites deletion in OSS")
            echo "${MENU}you have choosen Step 3 ${NORMAL}"
            if ! [ -f ${wdir}/to_delete.xml ]
                then
                    echo "The ${wdir}/to_delete file doesn't exist. Go to the Step 2, generate that files and return here. ".
                    #;; #from the end of cycle
                else
                    echo "The validation of xml file for RBS sites deletion is ongoing....."
                    echo -e "${ENTER_LINE}Be sure, that at the end of validation you are able to see (Example): ${MENU} There were 0 errors reported during validation ${NORMAL}"
                    /opt/ericsson/arne/bin/import.sh -f ${wdir}/to_delete.xml -val:rall
                    echo "${ENTER_LINE}Do you wish to run import for start deletion of ERBS sites, ${RED_TEXT} press (y/n)? ${NORMAL}"
                    read answer
                    if [ "$answer" != "${answer#[Yy]}" ] ;then
                        echo "I will need to stop two OSS services before importing.."
                        echo "Now, their status before stopping are:"
                        /opt/ericsson/nms_cif_sm/bin/smtool -l | egrep 'MAF|FM_ims'
                        echo "Run stop OSS services command.."
                        /opt/ericsson/nms_cif_sm/bin/smtool offline "MAF" -reason=upgrade -reasontext="Large Node Import"
                        /opt/ericsson/nms_cif_sm/bin/smtool offline "FM_ims" -reason=upgrade -reasontext="MAF offline"
                        sleep 3s
                        echo "Now, their status after stopping are:"
                        /opt/ericsson/nms_cif_sm/bin/smtool -l | egrep 'MAF|FM_ims'
                        echo "I performing importing xml for deletion.."
                        echo -e "${ENTER_LINE}Be sure, that at the end of importing you are able to see:"
                        echo -e "${MENU}Import Finished."
                        echo -e "${MENU}No Errors Reported."
                        /opt/ericsson/arne/bin/import.sh -import -f to_delete.xml
                        echo "Run start OSS services command.."
                        /opt/ericsson/nms_cif_sm/bin/smtool online "MAF" 
                        /opt/ericsson/nms_cif_sm/bin/smtool online "FM_ims"
                        sleep 3s
                        echo "Now, their status after starting are:"
                        /opt/ericsson/nms_cif_sm/bin/smtool -l | egrep 'MAF|FM_ims'
                    else
                        echo "Your choice is No. Enter up level.."
                        #;; from the end of cycle
                    fi
            fi
            echo -e "${ENTER_LINE}Step 3 is finished. Go to the next step!"
            show_menu
            ;;
        "Step 4: Apply ERBS sites creation into subnet in OSS")
            echo "you have choosen Step 4"
            if ! [ -f ${wdir}/to_create.xml ]
                then
                    echo "The ${wdir}/to_create.xml file doesn't exist. Go to the Step 2, generate that files and return here. ".
                    #;; #from the end of cycle
                else
                    echo "The validation of xml file for ERBS sites creation is ongoing....."
                    echo -e "${ENTER_LINE}Be sure, that at the end of validation you are able to see (Example): ${MENU} There were 0 errors reported during validation ${NORMAL}"
                    /opt/ericsson/arne/bin/import.sh -f ${wdir}/to_create.xml -val:rall
                    echo -e "${ENTER_LINE}Do you wish to run import for start creation of SIU/TCU, ${RED_TEXT} press (y/n)? ${NORMAL}"
                    read answer
                    if [ "$answer" != "${answer#[Yy]}" ] ;then
                        echo "I will need to stop two OSS services before importing.."
                        echo "Now, their status before stopping are:"
                        /opt/ericsson/nms_cif_sm/bin/smtool -l | egrep 'MAF|FM_ims'
                        echo "Run stop OSS services command.."
                        /opt/ericsson/nms_cif_sm/bin/smtool offline "MAF" -reason=upgrade -reasontext="Large Node Import"
                        /opt/ericsson/nms_cif_sm/bin/smtool offline "FM_ims" -reason=upgrade -reasontext="MAF offline"
                        sleep 3s
                        echo "Now, their status after stopping are:"
                        /opt/ericsson/nms_cif_sm/bin/smtool -l | egrep 'MAF|FM_ims'
                        echo "I performing importing xml for creation.."
                        echo -e "${ENTER_LINE}Be sure, that at the end of importing you are able to see:"
                        echo -e "${MENU}Import Finished."
                        echo -e "${MENU}No Errors Reported."
                        /opt/ericsson/arne/bin/import.sh -import -f to_create.xml
                        echo "Run start OSS services command.."
                        /opt/ericsson/nms_cif_sm/bin/smtool online "MAF" 
                        /opt/ericsson/nms_cif_sm/bin/smtool online "FM_ims"
                        sleep 3s
                        echo "Now, their status after starting are:"
                        /opt/ericsson/nms_cif_sm/bin/smtool -l | egrep 'MAF|FM_ims'
                    else
                        echo "Your choice is No. Enter up level.."
                        #;; from the end of cycle
                    fi
            fi
            echo -e "${ENTER_LINE} Step 4 is finished. Go to the next step!"
            show_menu
            ;;
        "Step 5: Show readme.txt file")
            cat readme.txt
            echo -e "${ENTER_LINE}Step 5 is finished. Go to the next step! ${NORMAL}"
            show_menu
            ;;
        "Step 6: Quit")
            break
            ;;
        *) echo invalid option;;
    esac
done
