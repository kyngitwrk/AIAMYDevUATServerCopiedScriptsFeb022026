-bash-5.2# crontab -l
#
# Copyright (c) 1989, 2016, Oracle and/or its affiliates. All rights reserved.
#
# The root crontab should be used to perform accounting data collection.
#

# System Performance Statistics
0 * * * * /usr/lib/sa/sa1 900 4 > /dev/null 2>&1
0 0 1 * * cp -p /var/adm/sa/sa?? /amdc/ts/sa > /dev/null 2>&1

#
10 3 * * * /usr/sbin/logadm
30 3 * * * [ -x /usr/lib/gss/gsscred_clean ] && /usr/lib/gss/gsscred_clean
0 0 * * * /usr/sbin/audit -n
# Restarting daily tsm scheduler
0 12 * * * /amdc/ts/scripts/tsm_sched_daily_restart.sh  > /dev/null 2>&1

# DB Backup
0 20 * * * /amdc/co/scripts/db_backup_auto_KDSYB01.sh > /dev/null 2>&1
30 20 * * * /amdc/co/scripts/db_backup_auto_KDSYB04.sh > /dev/null 2>&1
50 19 * * * /amdc/co/scripts/db_backup_auto_KDSYB03.sh > /dev/null 2>&1

# Sybase Database Disk Usage Monitor
#0 8,16 * * * /amdc/ts/scripts/dbsize.sh > /dev/null 2>&1
#5 8 1 * * /amdc/ts/scripts/mthsize.sh > /dev/null 2>&1
0,15,30,45 * * * * /amdc/ts/scripts/sybdum.sh > /dev/null 2>&1


# Update Statistic for Sybase Database
0 20 * * 3 /amdc/ts/scripts/updstat1 > /dev/null 2>&1
0 20 * * 4 /amdc/ts/scripts/updstat2 > /dev/null 2>&1
0 20 * * 5 /amdc/ts/scripts/updstat3 > /dev/null 2>&1
0 20 * * 6 /amdc/ts/scripts/updstat4 > /dev/null 2>&1
0 20 * * 0 /amdc/ts/scripts/updstat5 > /dev/null 2>&1

#Sybase Check Error Log
59 * * * * /amdc/ts/scripts/syberr.sh > /dev/null 2>&1

15,30,45,59 18-22 * * * /amdc/ts/scripts/sp_monitorconfig.sh > /dev/null 2>&1

1,6,11,16,21,26,31,36,41,46,51,56 18-22 * * 1-6 /amdc/ts/scripts/chkblk2.sh > /amdc/ts/logs/chkblk2.err 2>&1

# Monthly RU count
0 6 10,20,25 * * /amdc/ts/scripts/rucount.sh > /dev/null 2>&1

# Unix daily dashboard check fs and cpu
30 16 * * * /amdc/ts/scripts/dailyd.sh > /dev/null 2>&1

# Unix Housekeeping Job
0 23 * * * /amdc/ts/scripts/housekeep_ux.sh > /dev/null 2>&1


#To get procedure call audits.
#57 23 * * * /amdc/co/scripts/ProcAudit.sh
12,42 * * * * /var/opt/ansible/GTS/ILMT/bin/run_hw_CRON.sh  >/dev/null 2>&1

30 0 5 * * "/usr/lib/explorer/bin/explorer" -q # Explorer 20.1
0 2 * * * /var/opt/ansible/GTS/CIT/scan_aic.sh /var/opt/ansible/GTS/ILMT
-bash-5.2# cat /amdc/co/scripts/ProcAudit.sh
#!/bin/ksh
#

SYBASE=/sybase
. $SYBASE/SYBASE.sh
CONSOLE=`tty`

function AUDIT
{
SERVER=$1
LOGFILE=/amdc/co/logs/$SERVER/procaudit.log
#. /sybase/password/$SERVER.kcop701
. /sybase/password/$SERVER.sa
ISQL="/sybase/bin/isql -U$USER -S$SERVER -I/sybase/interfaces -w1000"

echo "$SERVER `date`" > $LOGFILE


        $ISQL << EOF | tee -a $CONSOLE $LOGFILE
$PASSWD
select count(*) "Before" from proc_audit..audit_records
go
insert into proc_audit..audit_records select * from sybsecurity..sysaudits_01 a where audit_event_name (event)='Execution of Stored Procedure' and dbname in (
'db_aes',
'db_aiaconfig',
'db_claims',
'db_cor',
'db_iws',
'db_nb',
'db_pa',
'db_pdf',
'db_pos2',
'db_pos2_restore',
'db_print',
'db_ul'

)
and not exists (select 1 from proc_audit..audit_records b where a.eventtime=b.eventtime)

go
insert into proc_audit..audit_records select * from sybsecurity..sysaudits_02 a where audit_event_name (event)='Execution of Stored Procedure' and dbname in (
'db_aes',
'db_aiaconfig',
'db_claims',
'db_cor',
'db_iws',
'db_nb',
'db_pa',
'db_pdf',
'db_pos2',
'db_pos2_restore',
'db_print',
'db_ul'

)
and not exists (select 1 from proc_audit..audit_records b where a.eventtime=b.eventtime)
go
select count(*) "After" from proc_audit..audit_records
go

select  eventtime,convert(varchar(30),loginname),convert(varchar(40),objname) "Proc name",convert(varchar(30),dbname),convert(varchar(255),extrainfo) from sybsecurity..sysaudits_01 where audit_event_name (event)='Execution of Stored Procedure' and dbname in (
'db_aes',
'db_aiaconfig',
'db_claims',
'db_cor',
'db_iws',
'db_nb',
'db_pa',
'db_pdf',
'db_pos2',
'db_pos2_restore',
'db_print',
'db_ul'

)
and CONVERT(DATE, eventtime) = CONVERT(DATE, GETDATE())
union
select  eventtime,convert(varchar(30),loginname),convert(varchar(40),objname) "Proc name",convert(varchar(30),dbname),convert(varchar(255),extrainfo) from sybsecurity..sysaudits_02 where audit_event_name (event)='Execution of Stored Procedure' and dbname in (
'db_aes',
'db_aiaconfig',
'db_claims',
'db_cor',
'db_iws',
'db_nb',
'db_pa',
'db_pdf',
'db_pos2',
'db_pos2_restore',
'db_print',
'db_ul'

)

and CONVERT(DATE, eventtime) = CONVERT(DATE, GETDATE())

go
EOF






# "\nThe followings are procedure call details for $SERVER:" >> $LOGFILE
#echo "-----------------------------------------------------\n" >> $LOGFILE

echo "" >> $LOGFILE

find /amdc/co/logs/$SERVER/procaudit.log -mtime +36 -exec rm -f {} \;

# Send mail to support staff
#. /amdc/ts/maillst/mailrcp
#mailx -s "`hostname` : Sybase UAT $SERVER Procedure call Report." $DBARCP $CORCP < $LOGFILE
mailx -s "`hostname` : Sybase UAT $SERVER Procedure call Report." abhiraj.thakur@kyndryl.com yan.peng@kyndryl.com < $LOGFILE

}


AUDIT KDSYB01

-bash-5.2#
