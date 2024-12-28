Connect-MgGraph

$intuneDevice = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.cm/beta/devicemanagment/managedDevices/DEVICE GUID"

$intuneDevice | ogv