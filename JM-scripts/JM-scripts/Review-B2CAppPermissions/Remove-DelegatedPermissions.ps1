function main {
    $TenantId = "e712b66c-2cb8-430e-848f-dbab4beb16df" # Provide MGIADPRD Tenant
    $NameSuffix = "EXTADDS" # Provide the suffix to filter by

    $Parameters = @{
        TenantId = $TenantId
        NameSuffix = $NameSuffix
    }

    Remove-DelegatedPermissions @Parameters
}

function Remove-DelegatedPermissions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [Guid]
        $TenantId,

        [Parameter(Mandatory)]
        [string]
        $NameSuffix
    )

    $requiredScopes = @(
        "Application.ReadWrite.All",
        "DelegatedPermissionGrant.ReadWrite.All"
    )

    # Connect to Microsoft Graph
    $null = Connect-MgGraph -Scopes $requiredScopes -TenantId $TenantId

    # Get all B2C app registrations
    $apps = Get-MgApplication -All #| Where-Object { $_.DisplayName -like "*$NameSuffix" }

    foreach ($app in $apps) {
        Write-Host "Reviewing App: $($app.DisplayName) - ID: $($app.Id)"

        # Get the service principal associated with the app
        $servicePrincipal = Get-MgServicePrincipal -Filter "AppId eq '$($app.AppId)'"

        if ($servicePrincipal) {
            # Get API permissions assigned to the app
            $apiPermissions = Get-MgServicePrincipalOauth2PermissionGrant -ServicePrincipal $servicePrincipal.Id
            Write-Host " - Found $($apiPermissions.Count) permissions grant for Service Principal ID: $($servicePrincipal.Id)"

            if ($apiPermissions) {
                foreach ($perm in $apiPermissions) {
                    # Remove Admin Access Grant
                    Write-Host " - Found Delegated Permission: $($perm.Scope) (Removing...)"
                    Remove-MgOauth2PermissionGrant -Oauth2PermissionGrantId $perm.Id
                }
            } else {
                Write-Host "No OAuth2 permissions found for Service Principal ID: $($servicePrincipalId)"
            }
        } else {
            Write-Host "No Service Principal found for AppId: $($app.AppId)"
        }
    }

    Write-Host "Delegated permissions review completed."

    Disconnect-MgGraph | Out-Null
}

main