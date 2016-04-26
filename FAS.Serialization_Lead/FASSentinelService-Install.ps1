# Script to install FAS Sentinel Serialization Services

# Helper functions to delete a previous installation

# Check if a service exists with a name as defined in $ServiceName.
Function ServiceExists([string] $ServiceName) {
    [bool] $Return = $False
    if ( Get-WmiObject -Class Win32_Service -Filter "Name='$ServiceName'" ) {
        $Return = $True
    }
    Return $Return
}

# Delete a Service with a name as defined in $ServiceName.
# Returns a boolean $True or $False.  $True if the Service didn't exist or was 
# successfully deleted after execution.
Function DeleteService([string] $ServiceName) {
    [bool] $Return = $False
    $Service = Get-WmiObject -Class Win32_Service -Filter "Name='$ServiceName'" 
    if ( $Service ) {
        $Service.Delete()
        if ( -Not ( ServiceExists $ServiceName ) ) {
            $Return = $True
        }
    } else {
        $Return = $True
    }
    Return $Return
}

$FAServices = @(@{'Name' = 'FAS_Configuration'; 'DisplayName' = 'FAS Sentinel Configuration Service'; 'Executable' = 'FAS.Configuration.WindowsService.exe'},
                @{'Name' = 'FAS_RequestQueue';  'DisplayName' = 'FAS Sentinel Request Queue Service'; 'Executable' = 'FAS.Sentinel.Serialization.RequestQueueService.exe'},
                @{'Name' = 'FAS_Serialization'; 'DisplayName' = 'FAS Sentinel Serialization Service'; 'Executable' = 'FAS.Sentinel.Serialization.WindowsService.exe'})


# Assumes standard installation path
#TODO: Can this be derived from the registry?
$FAFolder = $env:ProgramFiles + "\TCSC\FAS Sentinel Serialization Services"

# Get service account name and password
$credential = $Host.UI.PromptForCredential("FA Service Account", "Enter FA service account name and password.", "", "NetBiosUserName")

# Install each of the services (in the stopped state)
foreach ($FAService in $FAServices)
{
    $FAPath = $FAFolder + '\' +$FAService.Executable
    stop-service -Name $FAService.Name
    $tf = DeleteService $FAService.Name
    new-service -Name $FAService.Name -BinaryPathName "$FAPath" -DisplayName $FAService.DisplayName -Credential $credential
}
