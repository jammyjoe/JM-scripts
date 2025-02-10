function main {
    $TenantId = "e712b66c-2cb8-430e-848f-dbab4beb16df"
    
    $ObjectId = ""                       # ObjectId for an App Registration to update
    $ApplicationName = "Test"            # Application Name
    $Purpose = "Testing"                 # The application's function
    $OwningTeam = "Calypso"              # Department/Team Name
    $PrimaryContact = "Jamil Munayem"    # Email or Distribution List
    $CreatedBy = "Jamil Munayem"         # User/Service Principal
    $CurrentStatus = "Active"            # Active / Deprecated / Under Review
    
    $NewNotes =
"Application Name: $ApplicationName
Purpose: $Purpose
Owning Team: $OwningTeam
Primary Contact: $PrimaryContact
Created By: $CreatedBy
Date Created: $(Get-Date)
Current Status: $CurrentStatus

Notes:"

    $Parameters = @{
        TenantId = $TenantId
        ObjectId = $ObjectId
        NewNotes = $NewNotes 
      }

    # Call function with parameters
    Manage-AppRegistrations @Parameters
}

function Manage-AppRegistrations {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [Guid]
        $TenantId,

        [Guid]
        $ObjectId,

        [string]
        $NewNotes
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

    # Update a specific app registration
    Update-AppRegistrationNotes -ObjectId $ObjectId -NewNotes $NewNotes

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
        [string]
        $ObjectId,

        [Parameter(Mandatory)]
        [string]
        $NewNotes
        )

    Update-MgApplication -ApplicationId $ObjectId -Notes $NewNotes
    Write-Host "Updated App Registration ($ObjectId) with notes: $NewNotes"
}

main
