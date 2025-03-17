# RDLogOff
A simple PowerShell script to notify and then log off all but one specific user from a RD server. Specifically designed to be used to log off all but the QB Backup user to ensure proper nightly backup of *QuickBooks*.

## Usage
Designed to be setup and ran as a scheduled task. Various variables in the script need to be modified such as your **log path**, **server name**, **non log off user**, **log off time**, etc. 

This script is two stages, the notification and then the log off. Whatever time you set between the notification and the log off is how long the script sleeps before each function.

