# RDLogOff
# - - - - - 
# Script to notify then log-off all user execpt a specifc user.
# Designed to be setup and ran as a scheduled task.

# SCRIPT BEHAVIOR
# - - - - - - - -
# Upon script being ran we gather a list of all user sessions to be logged off that are NOT our specified user.
# We then send a message popup to the users notifying them of the log off and how long to stay logged off.
# The script then pauses for the designated ammount of time, then logs the users off.

# Brayden Kukla - 2025


# Log Path
$log = "C:\Scripts\RDLogOff\Logs\log.txt"
# User we do NOT want to log off
$nonLogOffUser = "USER-TO-NOT-LOG-OFF"
# Get RD sessions
$sessions = quser
# Log Off Users
$logOffUsers = @()
# Log Off Session IDs
$logOffIDs = @() 
# RD Server
$server = "YOUR-RD-SERVER" 
# Time told to users in message to stay logged off for (mins)
$stayLogOffTime = 15
# Time before logout (mins)
$logOffCountdown = 5
# Message to send to users
$msg = 
"
You will be logged out in $logOffCountdown minutes to allow for nightly backups, please stay logged out for $stayLogOffTime minutes to allow backups to complete successfully.

Thank you
- IT Dept.
"

# Check if the log outs were successful
function LogOutSuccess() {
    $sessions = quser
    foreach($session in $sessions) {
        # Get session info
        $info = ($session -split ' ') | Where-Object { $_ -ne ''} #0=USERNAME, 1=SESSIONNAME, 2=ID, 3=STATE, #4=IDLETIME, 5=LOGONTIME
        $username = $info[0] -replace "\W" #Clean user string                                          

        # Get all users to log off except specified user, also filtering the first entry in the array which is the header
        # and see if our specified user is the only one left logged in
       if ($username -eq "USERNAME") {
            continue
       } else { 
            if ($username -ne $nonLogOffUser) {
                $success = $false 
                break
            } else {
                $success = $true
            }
       }
    }
    return $success
}


# Get the sessions we are going to be logging off
foreach ($session in $sessions) {
    # Get session info
    $info = ($session -split ' ') | Where-Object { $_ -ne ''} #0=USERNAME, 1=SESSIONNAME, 2=ID, 3=STATE, #4=IDLETIME, 5=LOGONTIME
    $username = $info[0] -replace "\W" #Clean user string                                      
    $id = $info[2]

    # Get all users to log off except specified user, also filtering the first entry in the array which is the header
    if ($username -ne $nonLogOffUser -and $username -ne "USERNAME") {
        $logOffUsers += $username
        $logOffIDs += $id
    } 
}


# End script if there are no users to log off
if ($logOffUsers.Count -eq 0) {    
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"  
    Add-Content -Path $log -Value "$ts - NO USERS TO LOG OFF, ENDING SCRIPT..."
    exit
}


# Send message to users notifying of the log off
foreach ($user in $logOffUsers) { 
    Msg /server:$server/ $user $msg
    Write-Host "Sending log off message to user : $user"
}


# Wait for the specified time before logging users out
Start-Sleep -Seconds ($logOffCountdown * 60)


# Finally log off users
foreach ($user in $logOffUsers) {
    $index = [array]::IndexOf($logOffUsers, $user)
    $id = $logOffIDs[$index]

    # Attempt to log off user
    try {
        logoff $id
        Write-Host "Logged off user $user..."
    } catch { # Catch any failed log offs and save in log
        $err = $_.Exception.Message
        $stack = $_.Exception.StackTrace
        $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"    
        Add-Content -Path $log -Value "$ts - ERROR - UNABLE TO LOGOFF USER $user : $err, $stack"
    }
}


# Wait for log offs
Start-Sleep -Seconds 30 


# Lastly lets write results to the log
if (LogOutSuccess -eq $true) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"    
    Add-Content -Path $log -Value "$ts - SUCCESS - Logged off all users...$logOffUsers"
} else {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"    
    Add-Content -Path $log -Value "$ts - ERROR - Unable to log all users off, refer to the log for errors on specific users..."
}
