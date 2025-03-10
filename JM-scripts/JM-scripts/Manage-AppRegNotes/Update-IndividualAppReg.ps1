function main {
    $TenantId = "e712b66c-2cb8-430e-848f-dbab4beb16df" # Provide UKHO Tenant
    
    $DefaultCsvFilePath ="D:\Users\MunayemJ\repos\Calypso\PowershellScripts\JM-scripts\JM-scripts\default_template.csv"
    $IndividualCsvFilePath ="D:\Users\MunayemJ\repos\Calypso\PowershellScripts\JM-scripts\JM-scripts\individual_template.csv"


    $Parameters = @{
        TenantId    = $TenantId
        DefaultCsvFilePath =  $DefaultCsvFilePath
        IndividualCsvFilePath = $IndividualCsvFilePath
    }

    Manage-AppRegistrations @Parameters
}

function Manage-AppRegistrations {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [Guid]
        $TenantId,

        [Parameter(Mandatory)]
        [string]
        $DefaultCsvFilePath,

        [Parameter(Mandatory)]
        [string]
        $IndividualCsvFilePath
    )

    $requiredScopes = @(
        "Application.ReadWrite.All" # Needed for MgApplication Cmdlets
    )

    # Connect to Microsoft Graph
    $null = Connect-MgGraph -Scopes $requiredScopes -TenantId $TenantId

    # Update a specific App Registration internal notes
    Update-AppRegistrationNotes -IndividualCsvFilePath $IndividualCsvFilePath

    Disconnect-MgGraph | Out-Null
}

function Update-AppRegistrationNotes {
    param (
        [Parameter(Mandatory)]
        [string]$IndividualCsvFilePath
    )

    # Import the CSV file.
    $csvData = Import-Csv -Path $IndividualCsvFilePath

    if ($csvData.Count -eq 0) {
        Write-Error "CSV file is empty. Please provide valid data."
        return
    }

    if ($csvData.Count -gt 1024) {
        Write-Host "Error: Notes exceed 1024-character limit. Please shorten your input."
        return
    }
    
    foreach ($row in $csvData) {
        Write-Host "Updating app registration $($row.ObjectId) with the following note:" -ForegroundColor Cyan
        Write-Host $row.Note -ForegroundColor Yellow

        try {
            Update-MgApplication -ApplicationId $row.ObjectId -Notes $row.Note
            Write-Host "Successfully updated $($row.ObjectId)." -ForegroundColor Green
        }
        catch {
            Write-Host "Error updating $($row.ObjectId): $_" -ForegroundColor Red
        }
    }
}

main
