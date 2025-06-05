#!/bin/sh
# =============================================================================
#
# ftphome.sh
#
# script to setup anonymous ftp area on Solaris 7
# extracted from the ftpd man page
#
# =============================================================================

# verify you are root
/usr/bin/id | grep -w 'uid=0' >/dev/null 2>&1
if [ "$?" != "0" ]; then
    echo
    exit 1
fi

# handle the optional command line argument
case $# in

    # the default location for the anon ftp comes from the passwd file
    0) ftphome="`getent passwd ftp | cut -d: -f6`"
       ;;

    1) if [ "$1" = "start" ]; then
           ftphome="`getent passwd ftp | cut -d: -f6`"
       else
           ftphome=$1
       fi
       ;;

    *) echo "Usage: $0 [anon-ftp-root]"
       exit 1
       ;;
esac

if [ -z "${ftphome}" ]; then
    echo "$0: ftphome must be non-null"
    exit 2
fi

case ${ftphome} in
    /*) # ok
        ;;

    *) echo "$0: ftphome must be an absolute pathname"
       exit 1
       ;;
esac

# This script assumes that ftphome is neither / nor /usr so ...
if [ -z "${ftphome}" -o "${ftphome}" = "/" -o "${ftphome}" = "/usr" ]; then
    echo "$0: ftphome must be non-null and neither / or /usr"
    exit 2
fi

# If ftphome does not exist but parent does, create ftphome
if [ ! -d ${ftphome} ]; then
    # lack of -p below is intentional
    mkdir ${ftphome}
fi
chown root ${ftphome}
chmod 555 ${ftphome}

echo Setting up anonymous ftp area ${ftphome}

# Ensure that the /usr directory exists
if [ ! -d ${ftphome}/usr ]; then
    mkdir -p ${ftphome}/usr
fi
# Now set the ownership and modes to match the man page
chown root ${ftphome}/usr
chmod 555 ${ftphome}/usr

# Ensure that the /usr/bin directory exists
if [ ! -d ${ftphome}/usr/bin ]; then
    mkdir -p ${ftphome}/usr/bin
fi
# Now set the ownership and modes to match the man page
chown root ${ftphome}/usr/bin
chmod 555 ${ftphome}/usr/bin

# this may not be the right thing to do
# but we need the bin -> usr/bin link
rm -f ${ftphome}/bin
ln -s usr/bin ${ftphome}/bin

# Ensure that the /usr/lib and /etc directories exist
if [ ! -d ${ftphome}/usr/lib ]; then
    mkdir -p ${ftphome}/usr/lib
fi
chown root ${ftphome}/usr/lib
chmod 555 ${ftphome}/usr/lib

if [ ! -d ${ftphome}/usr/lib/security ]; then
    mkdir -p ${ftphome}/usr/lib/security
fi
chown root ${ftphome}/usr/lib/security
chmod 555 ${ftphome}/usr/lib/security

if [ ! -d ${ftphome}/etc ]; then
    mkdir -p ${ftphome}/etc
fi
chown root ${ftphome}/etc
chmod 555 ${ftphome}/etc

# a list of all the commands that should be copied to ${ftphome}/usr/bin
# /usr/bin/ls is needed at a minimum.
ftpcmd="
    /usr/bin/ls
"

# ${ftphome}/usr/lib needs to have all the libraries needed by the above
# commands, plus the runtime linker, and some name service libraries
# to resolve names. We just take all of them here.

ftplib="`ldd $ftpcmd | nawk '$3 ~ /lib/ { print $3 }' | sort | uniq`"
ftplib="$ftplib /usr/lib/nss_* /usr/lib/straddr* /usr/lib/libmp.so*"
ftplib="$ftplib /usr/lib/libnsl.so.1 /usr/lib/libsocket.so.1 /usr/lib/ld.so.1"
ftplib="`echo $ftplib | tr ' ' '\n' | sort | uniq`"

cp ${ftplib} ${ftphome}/usr/lib
chmod 555 ${ftphome}/usr/lib/*

cp /usr/lib/security/* ${ftphome}/usr/lib/security
chmod 555 ${ftphome}/usr/lib/security/*

cp ${ftpcmd} ${ftphome}/usr/bin
chmod 111 ${ftphome}/usr/bin/*

# you also might want to have separate minimal versions of passwd and group
cp /etc/passwd /etc/group /etc/netconfig /etc/pam.conf ${ftphome}/etc
chmod 444 ${ftphome}/etc/*

# need /etc/default/init for timezone to be correct
if [ ! -d ${ftphome}/etc/default ]; then
    mkdir ${ftphome}/etc/default
fi
chown root ${ftphome}/etc/default
chmod 555 ${ftphome}/etc/default
cp /etc/default/init ${ftphome}/etc/default
chmod 444 ${ftphome}/etc/default/init

# Copy timezone database
mkdir -p ${ftphome}/usr/share/lib/zoneinfo

(cd ${ftphome}/usr/share/lib/zoneinfo
    (cd /usr/share/lib/zoneinfo; find . -print |
    cpio -o) 2>/dev/null | cpio -imdu 2>/dev/null
    find . -print | xargs chmod 555
    find . -print | xargs chown root
)

# Ensure that the /dev directory exists
if [ ! -d ${ftphome}/dev ]; then
    mkdir -p ${ftphome}/dev
fi

# make device nodes. ticotsord and udp are necessary for
# 'ls' to resolve NIS names.

for device in zero tcp udp ticotsord ticlts
do
    line=`ls -lL /dev/${device} | sed -e 's/,//'`
    major=`echo $line | awk '{print $5}'`
    minor=`echo $line | awk '{print $6}'`
    rm -f ${ftphome}/dev/${device}
    mknod ${ftphome}/dev/${device} c ${major} ${minor}
done

chmod 666 ${ftphome}/dev/*

## Now set the ownership and modes
chown root ${ftphome}/dev
chmod 555 ${ftphome}/dev

# uncomment the below if you want a place for people to store things,
# but beware the security implications
if [ ! -d ${ftphome}/pub ]; then
    mkdir -p ${ftphome}/pub
fi
chown root ${ftphome}/pub
chmod 1755 ${ftphome}/pub

