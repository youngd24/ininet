#!/bin/bash
LATEST=$(lynx --source  http://phrack.org/archives/tgz/|grep -oP '(?<=phrack)[0-9]{2}'|sort -n|tail -1)  
for (( i=1; i<=LATEST; i++ ))  
do  
        FILE="phrack${i}.tar.gz"  
        echo "Getting file: $FILE"
        wget http://phrack.org/archives/tgz/${FILE}  
        if [ ! -d phrack${i} ]; then  
                mkdir -p phrack${i};  
        fi 
        echo "Untarring file $FILE"
        tar xvzf ${FILE} -C ./phrack${i}/  
        #rm ${FILE}
done
