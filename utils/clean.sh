#!/usr/bin/sh

tftpdir="/srv/tftp/ininet"

for file in `cd $tftpdir && ls *conf*`;
do
    echo "Cleaning $tftpdir/$file"
    cat $tftpdir/$file | \
	    grep -v username | \
	    grep -v 'enable pass' | \
	    grep -v 'enable sec' | \
	    grep -v 'tacacs-server key' > ../configs/$file
done
