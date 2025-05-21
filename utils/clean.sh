#!/usr/bin/sh

tftpdir="/srv/tftp/ininet"

for file in `cd $tftpdir && ls *conf*`;
do
    echo "Cleaning $tftpdir/$file"
    cat $tftpdir/$file | grep -v username | grep -v 'enable pass' | grep -v 'enable sec' > ../configs/$file
done
