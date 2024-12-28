#Microsoft Teams PwSH Install#
Install-Module -Name PowerShellGet -Force -AllowClobber
Install-Module -Name MicrosoftTeams -Force -AllowClobber

Connect-MicrosoftTeams


#Exchange Online PwSH Install#
Install-Module -Name ExchangeOnlineManagement

Connect-ExchangeOnline


#Azure Active Directory Install#
Install-Module -Name AzureAD

Connect-AzureAD

#Microsoft Graph Powershell Module Install#
Install-Module -Name Microsoft.Graph

Connect-MgGraph

#SharePoint Online Management Shell Install#
Install-Module -Name Microsoft.Online.SharePoint.PowerShell

Connect-SPOService -Url https://yourdomain-admin.sharepoint.com

#MSOnline Module (Legacy) Install#
Install-Module -Name MSOnline

Connect-MsolService

#Security & Compliance Center Module#
Install-Module -Name ExchangeOnlineManagement

Connect-IPPSSession

#Microsoft Intune Module (Microsoft.Graph.Intune)#
Install-Module -Name Microsoft.Graph.Intune

Connect-MSGraph







