Connect-AzAccount

New-AzUserAssignedIdentity -Name "CalendarAutomationUA" -ResourceGroupName "rg-automation-cal" -Location "Central US"

$MI_ID = (Get-AzADServicePrincipal -DisplayName "calendarautomationua").Id

$MI_ID

Install-Module Microsoft.Graph -Force

Connect-MgGraph -Scopes AppRoleAssignment.ReadWrite.All,Application.Read.All

Import-Module Microsoft.Graph.Applications

Get-MgServicePrincipal -Filter "AppId eq '00000002-0000-0ff1-ce00-000000000000'"

$AppRoleID = "dc50a0fb-09a3-484d-be87-e023b12c6440"

$ResourceID = (Get-MgServicePrincipal -Filter "AppId eq '00000002-0000-0ff1-ce00-000000000000'").Id

New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $MI_ID -PrincipalId $MI_ID -AppRoleId $AppRoleID -ResourceId $ResourceID

Get-MgServicePrincipal -Filter "AppId eq '00000002-0000-0ff1-ce00-000000000000'" | Select-Object -ExpandProperty AppRoles | Format-Table Value,Id

Connect-MgGraph -Scopes RoleManagement.ReadWrite.Directory

$RoleID = (Get-MgRoleManagementDirectoryRoleDefinition -Filter "DisplayName eq 'Exchange Administrator'").Id

New-MgRoleManagementDirectoryRoleAssignment -PrincipalId $MI_ID -RoleDefinitionId $RoleID -DirectoryScopeId "/"

Connect-ExchangeOnline -ManagedIdentity -Organization w3-llc.com -ManagedIdentityAccountId 7a519ddd-8ad1-490c-8a36-de7d97ee1bb6