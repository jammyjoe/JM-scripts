####################
# WHAT IS THIS SCRIPT
####################
# Removes all Delegated Permissions from the API Permissions of all B2C App Registrations with the suffix EXTADDS
# Used by Calypso as we no longer use Delegated Permissions and instead use client/secret to get an access tokem

########################
# HOW TO USE THIS SCRIPT
########################
# 0 - Predicates:
#     Ensure you have installed the Az module into your Powershell environment (v8.1.0 available from UKHO.PSGallery)
#
# 1 - Run the script: `.\Remove-ManifestApiPermissions.ps1`
#
# 2 - A browser login window will pop up when the Connect-MgGraph command is run


function main {
    $TenantId   = "e712b66c-2cb8-430e-848f-dbab4beb16df" # Provide MGIADPRD Tenant
    $NameSuffix = "EXTADDS" # Provide the suffix to filter by

    $Parameters = @{
        TenantId   = $TenantId
        NameSuffix = $NameSuffix
    }

    Remove-ManifestPermissions @Parameters
}

function Remove-ManifestPermissions
{
    [CmdletBinding()]
    param (
        # The Tenant ID of the Tenant where the B2C Customer App Reg will be stored
        [Parameter(Mandatory)]
        [Guid]
        $TenantId,
    
        # The EXTADDS suffix to filter only for the App registrations
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
        Write-Host "Reviewing App: $($app.DisplayName)"

        # Get the Service Principal associated with the App Reg
        $servicePrincipal = Get-MgServicePrincipal -Filter "AppId eq '$($app.AppId)'"
        $apiPermissions = Get-MgServicePrincipalOauth2PermissionGrant -ServicePrincipal $servicePrincipal.Id

        # Remove Admin Consent for API Permissions
        foreach ($perm in $apiPermissions)
        {
            Write-Host " - Revoking admin consent from API permissions..."
            Remove-MgOauth2PermissionGrant -Oauth2PermissionGrantId $perm.Id
        }

        # Use the App Regs' requiredResourceAccess property to modify API Permissions
        if ($app.RequiredResourceAccess.Count -gt 0)
        {
            $resourceAccess = $app.RequiredResourceAccess[0].ResourceAccess
            Write-Host " - Processing App registration: $($app.DisplayName) with $($resourceAccess.Count) API Permission(s)"

            $resourceAccess = $resourceAccess | Where-Object { $_.Type -eq 'Role' }

            if ($resourceAccess.Count -gt 0)
            {
                # Only keep Application Permissions (remove Delegated Permissions)

                $app.RequiredResourceAccess[0].ResourceAccess = $resourceAccess
                Update-MgApplication -ApplicationId $app.Id -RequiredResourceAccess $app.RequiredResourceAccess
                Write-Host " - $($app.DisplayName) has $($resourceAccess.Count) API Permission(s) remaining `n"
            }
            
            elseif ($resourceAccess.Count -eq 0)
            {
                # Remove all API Permissions if only Delegated Permissions exist
                
                $uri = "https://graph.microsoft.com/v1.0/applications/$($app.Id)"
                $body = @{
                    requiredResourceAccess = @()
                } | ConvertTo-Json -Depth 3

                Invoke-MgGraphRequest -Method PATCH -Uri $uri -Body $body -ContentType "application/json"
                Write-Host " - All API permissions removed for $($app.DisplayName) `n"
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