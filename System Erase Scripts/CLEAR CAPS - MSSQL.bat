net stop MSSQL$SQLEXPRESS

net start MSSQL$SQLEXPRESS /m

Sqlcmd -S .\sqlexpress -Q "alter login sa enable; alter login sa with password= '#1mymicros' unlock; alter login datastoredb enable; alter login datastoredb with password= 'datastoredb' unlock; drop database datastore; drop database checkpostingdb; drop database kdsdatastore;"

net stop MSSQL$SQLEXPRESS

net start MSSQL$SQLEXPRESS

net stop "MICROS CAL Client"

net stop "KDSController"

net stop "Oracle Hospitality Simphony Service Host"

reg delete "HKLM\SOFTWARE\WOW6432Node\Micros" /reg:64 /f

TAKEOWN /f C:\Micros\ /r /d y

ICACLS C:\Micros /grant administrators:F /t

rmdir "C:\Micros\" /s /q