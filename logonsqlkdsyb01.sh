#!/bin/ksh
#
# Logon to Sybase server.

SYBASE=/sybase; export SYBASE

echo
echo "Server Name (KPSYB01) : \c"
read SERVER
echo
case $SERVER in
        KPSYB01);;
        *) echo "Not a Valid Server Name";exit;;
esac
echo "Login ID : \c"
read LOGINID
echo

/sybase/bin/isql -S$SERVER -U$LOGINID -I/sybase/interfaces -w132
