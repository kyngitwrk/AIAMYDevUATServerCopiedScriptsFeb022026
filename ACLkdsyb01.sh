#!/bin/ksh
#
# Setup ACL.

chown root:sys dump*
chmod 700 dump*
chmod 4700 dumpunix
setfacl -m group:kpcopg00:r-x dumpunix
setfacl -m mask:r-x dumpunix
