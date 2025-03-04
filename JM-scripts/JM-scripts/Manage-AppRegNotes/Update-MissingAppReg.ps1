function main {
    $TenantId = "e712b66c-2cb8-430e-848f-dbab4beb16df" # Provide UKHO Tenant

    $Parameters = @{
        TenantId = $TenantId

      }
    
    Manage-AppRegistrations @Parameters
}

function Manage-AppRegistrations {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [Guid]
        $TenantId
    )
    
    $requiredScopes = @(
        "Application.ReadWrite.All" # Needed for MgApplication Cmdlets
    )
    
    # Connect to Microsoft Graph
    $null = Connect-MgGraph -Scopes $requiredScopes -TenantId $TenantId 
    
    # Display all App Registrations with their internal notes
    Get-AllAppRegistrations 
    
    # Update missing internal notes
    #Update-MissingInternalNotes

    Disconnect-MgGraph | Out-Null
}

function Get-AllAppRegistrations {
    $appRegs = Get-MgApplication -All | Select-Object DisplayName, Notes
    $appRegs | Format-Table -AutoSize
}

function Update-MissingInternalNotes {
    $appRegs = Get-MgApplication -All | Where-Object { [string]::IsNullOrEmpty($_.Notes) } #Notes does not support filtering
    $defaultNote = "Last updated on $(Get-Date)."

    foreach ($app in $appRegs) {
        Update-MgApplication -ApplicationId $app.Id -Notes $defaultNote
        Write-Host "Updated $($app.DisplayName) with internal notes."
    }
}

main
