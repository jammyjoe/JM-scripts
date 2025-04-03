####################
# WHAT IS THIS SCRIPT
####################
# Removes all Delegated Permissions from the API Permissions of all B2C App Registrations with the suffix EXTADDS
# Used by Calypso as we no longer use Delegated Permissions and instead use client/secret to get an access tokem

########################
# HOW TO USE THIS SCRIPT
########################
# WARNING:
# Setting $WhatIf to false will execute the script, it is defaulted to true to see what changes will be made and to prevent accidental runs
#
# 0 - Predicates:
#     Ensure you have installed the Microsoft.Graph module into your Powershell environment (v1.6.0 available from UKHO.PSGallery)
#      
# 1 - Run the script: `.\Remove-DelegatedApiPermissions.ps1`
#
# 2 - A browser login window will pop up when the Connect-MgGraph command is runfunction


function main {
    $TenantId   = "e712b66c-2cb8-430e-848f-dbab4beb16df" # Provide MGIADPRD Tenant
    $NameSuffix = "EXTADDS" # Provide the suffix to filter by
    $WhatIfPreference = $false # Setting this to $false will execute the script
    
    $Parameters = @{
        TenantId   = $TenantId
        NameSuffix = $NameSuffix
    }

    Remove-DelegatedApiPermissions @Parameters
}

function Remove-DelegatedApiPermissions {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [Guid]
        $TenantId,

        [Parameter(Mandatory)]
        [string]
        $NameSuffix
    )

    $requiredScopes = @(
        "Application.ReadWrite.All", # Needed for MgApplication Cmdlets
        "DelegatedPermissionGrant.ReadWrite.All" # Needed to remove Admin Consent from API Permissions
    )

    # Connect to Microsoft Graph
    $null = Connect-MgGraph -Scopes $requiredScopes -TenantId $TenantId

    # Get all B2C App Reg with EXTADDS suffix
    $apps = Get-MgApplication -All | Where-Object { $_.DisplayName -like "*$NameSuffix" }

    foreach ($app in $apps) 
    {
        Write-Host "Reviewing App: $($app.DisplayName)" -ForegroundColor Yellow

        # Get the Service Principal associated with the App Reg
        $servicePrincipal = Get-MgServicePrincipal -Filter "AppId eq '$($app.AppId)'"
        $apiPermissions = Get-MgServicePrincipalOauth2PermissionGrant -ServicePrincipal $servicePrincipal.Id

        # Remove Admin Consent for API Permissions
        foreach ($perm in $apiPermissions) 
        {    
            if ($PSCmdlet.ShouldProcess("Remove-MgOauth2PermissionGrant", "Remove Admin Consent for $($app.DisplayName)")) {
                Remove-MgOauth2PermissionGrant -Oauth2PermissionGrantId $perm.Id -WhatIf:$WhatIfPreference
            }
        }

        # Use the App Regs' requiredResourceAccess property to modify API Permissions
        if ($app.RequiredResourceAccess.Count -gt 0) 
        {
            $resourceAccess = $app.RequiredResourceAccess[0].ResourceAccess
            Write-Host " - Processing App registration: $($app.DisplayName) with $($resourceAccess.Count) API Permission(s)"

            $permissions = $resourceAccess | Group-Object Type -AsHashTable

            $delegatedPermissions = $permissions['Scope']
            $nonDelegatedPermissions = $permissions['Role']

            if ($nonDelegatedPermissions.Count -gt 0) 
            {
                # Only keep Application Permissions (remove Delegated Permissions)
                $app.RequiredResourceAccess[0].ResourceAccess = $nonDelegatedPermissions
                if ($PSCmdlet.ShouldProcess("Update-MgApplication", "Removing $($delegatedPermissions.Count) Delegated Permissions for $($app.DisplayName) and keeping $($nonDelegatedPermissions.Count) API Permission(s)"))
                {
                    Update-MgApplication -ApplicationId $app.Id -RequiredResourceAccess $app.RequiredResourceAccess -WhatIf:$WhatIfPreference
                }
                $resourceAccess = $app.RequiredResourceAccess[0].ResourceAccess
                Write-Host " - $($app.DisplayName) has $($resourceAccess.Count) API Permission(s) remaining `n"
            }

            elseif ($nonDelegatedPermissions.Count -eq 0)
            {
                # Remove all API Permissions if only Delegated Permissions exist
                if ($WhatIfPreference -eq $false) {
                    $uri = "https://graph.microsoft.com/v1.0/applications/$($app.Id)"
                    $body = @{
                        requiredResourceAccess = @()
                    } | ConvertTo-Json -Depth 3
                    Invoke-MgGraphRequest -Method PATCH -Uri $uri -Body $body -ContentType "application/json"
                    Write-Host " - All API permissions removed for $($app.DisplayName)"
                }
                else
                {
                    Write-Host "WhatIf: Removing $($delegatedPermissions.Count) Delegated Permissions for $($app.DisplayName) on target Invoke-MgGraphRequest."
                }
            }
        }
        
        else 
        {
            Write-Host " - No API Permissions found for $($app.DisplayName) `n"
        }
    }
    Disconnect-MgGraph | Out-Null
}

main