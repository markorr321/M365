Set-ExecutionPolicy Unrestricted -Force

# Retrieve uninstall strings for Microsoft 365 and OneNote
$OfficeUninstallStrings = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
    Where-Object { $_.DisplayName -like "*Microsoft 365*" -or $_.DisplayName -like "*OneNote*" } | 
    Select-Object -ExpandProperty UninstallString)

# Loop through each uninstall string and uninstall
ForEach ($UninstallString in $OfficeUninstallStrings) {
    $UninstallEXE = ($UninstallString -split '"')[1]
    $UninstallArg = ($UninstallString -split '"')[2] + " DisplayLevel=False"
    Start-Process -FilePath $UninstallEXE -ArgumentList $UninstallArg -Wait
}

# Exit the script with a success code
Exit 0

