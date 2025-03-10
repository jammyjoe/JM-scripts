function main {
    $TenantId = "e712b66c-2cb8-430e-848f-dbab4beb16df" # Provide UKHO Tenant
    $ObjectId = "31082794-fcbb-49b2-a06b-bf17768a86b0" # Provide App Reg Object Id
    $NewNotes = "Test notes"                                     # Provide notes for the app registration
    
    $Parameters = @{
        TenantId = $TenantId
        ObjectId = $ObjectId
        NewNotes = $NewNotes
    }

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

    # Update a specific app registration internal notes
    Update-AppRegistrationNotes -ObjectId $ObjectId -NewNotes $NewNotes

    Disconnect-MgGraph | Out-Null
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

    if ($NewNotes.Length -gt 1024) {
        Write-Host "Error: Notes exceed 1024-character limit. Please shorten your input."
        return
    }

    Update-MgApplication -ApplicationId $ObjectId -Notes $NewNotes
    Write-Host "Updated App Registration ($ObjectId) with notes: $NewNotes"
}

main