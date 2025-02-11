function main {
    $TenantId = "" # Provide UKHO Tenant

    $Parameters = @{
        TenantId    = $TenantId
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
    Update-MissingInternalNotes

    # Update a specific App Registration internal notes
     $AppId = ""    # Provide ObjectId of the app registration
     $NewNotes = "" #Provide new notes for the app registration
    
     Update-AppRegistrationNotes -AppId $AppId -Notes $NewNotes

    Disconnect-MgGraph | Out-Null
}

function Get-AllAppRegistrations {
    $appRegs = Get-MgApplication -All
    foreach ($app in $appRegs) {
        Write-Host "App Name: $($app.DisplayName)"
        Write-Host "Internal Notes: $($app.Notes)`n"
    }
}

function Update-MissingInternalNotes {
    $appRegs = Get-MgApplication -All | Where-Object { [string]::IsNullOrEmpty($_.Notes) }

    foreach ($app in $appRegs) {
        $defaultNote = "Last updated on $(Get-Date)."
        Update-MgApplication -ApplicationId $app.Id -Notes $defaultNote
        Write-Host "Updated $($app.DisplayName) with internal notes."
    }
}

function Update-AppRegistrationNotes {
    param (
        [Parameter(Mandatory)]
        [string]$AppId,

        [Parameter(Mandatory)]
        [string]$Notes
    )

    Update-MgApplication -ApplicationId $AppId -Notes $Notes
    Write-Host "Updated App Registration ($AppId) with notes: $Notes"
}

main
