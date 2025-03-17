function main {
    $TenantId = "e712b66c-2cb8-430e-848f-dbab4beb16df" # Provide MGIADPRD Tenant
    $NameSuffix = "EXTADDS" # Provide the suffix to filter by

    $Parameters = @{
        TenantId = $TenantId
        NameSuffix = $NameSuffix
    }

    Remove-ManifestPermissions @Parameters
}

function Remove-ManifestPermissions
{
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
        "Application.ReadWrite.All"
    )

    $null = Connect-MgGraph -Scopes $requiredScopes -TenantId $TenantId

    # Get all B2C app registrations
    $apps = Get-MgApplication -All | Where-Object { $_.DisplayName -like "*$NameSuffix" }

    foreach ($app in $apps)
    {
        Write-Host "Reviewing App: $( $app.DisplayName ) - ID: $( $app.Id )"
        $appManifest = Get-MgApplication -ApplicationId $app.Id

        # Check if there are any requiredResourceAccess entries
        if ($appManifest.RequiredResourceAccess.Count -gt 0)
        {
            Write-Host "Processing ResourceAppId: $( $app.DisplayName ) with $( $appManifest.RequiredResourceAccess[0].ResourceAccess.Count ) API Permissions."

            # Remove all 'Scope' type permissions from the single RequiredResourceAccess entry
            $filteredResourceAccess = $appManifest.RequiredResourceAccess[0].ResourceAccess | Where-Object { $_.Type -ne 'Scope' }

            # If the filtering results in no permissions, update the application with an empty RequiredResourceAccess array
            if ($filteredResourceAccess.Count -eq 0)
            {
                Write-Host "After filtering, no ResourceAccess entries remain. Removing API Permissions."
                # Set the ResourceAccess to an empty array or null based on the requirement
                $appManifest.RequiredResourceAccess[0].ResourceAccess = @()
            }
            else
            {
                Write-Host "After filtering, $( $filteredResourceAccess.Count ) ResourceAccess entries remain."
                $appManifest.RequiredResourceAccess[0].ResourceAccess = $filteredResourceAccess
            }

            # Now update the app registration with the modified RequiredResourceAccess
            Update-MgApplication -ApplicationId $app.Id -RequiredResourceAccess $appManifest.RequiredResourceAccess
        }
        else
        {
            Write-Host "No API Permissions found for $( $app.DisplayName )"
        }
    }
    Disconnect-MgGraph | Out-Null
}
main
