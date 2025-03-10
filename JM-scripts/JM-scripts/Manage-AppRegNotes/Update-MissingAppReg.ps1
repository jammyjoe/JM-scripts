function main {
    $TenantId = "e712b66c-2cb8-430e-848f-dbab4beb16df" # Provide UKHO Tenant
    $DefaultCsvFilePath ="D:\Users\MunayemJ\repos\Calypso\PowershellScripts\JM-scripts\JM-scripts\default_template.csv"


    $Parameters = @{
        TenantId    = $TenantId
        DefaultCsvFilePath =  $DefaultCsvFilePath
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
        $DefaultCsvFilePath
    )
    
    $requiredScopes = @(
        "Application.ReadWrite.All" # Needed for MgApplication Cmdlets
    )
    
    # Connect to Microsoft Graph
    $null = Connect-MgGraph -Scopes $requiredScopes -TenantId $TenantId 
    
    # Display all App Registrations with their internal notes
    Get-AllAppRegistrations 
    
    # Update missing internal notes
    Update-MissingInternalNotes -DefaultCsvFilePath $DefaultCsvFilePath

    Disconnect-MgGraph | Out-Null
}

function Get-AllAppRegistrations {
    $appRegs = Get-MgApplication -All | Select-Object DisplayName, Notes
    $appRegs | Format-Table -AutoSize
}

function Update-MissingInternalNotes {
    param (
        [Parameter(Mandatory)]
        [string]$DefaultCsvFilePath
    )

    # Import the CSV file.
    $csvData = Import-Csv -Path $DefaultCsvFilePath

    if ($csvData.Count -eq 0) {
        Write-Error "CSV file is empty. Please provide a default note template."
        return
    }

    # Use the note from the first row as the default template.
    $defaultNote = $csvData[0].Note
    Write-Host "Using the following default note template:" -ForegroundColor Cyan
    Write-Host $defaultNote -ForegroundColor Yellow

    # Retrieve all app registrations that have empty internal notes.
    $appRegs = Get-MgApplication -All | Where-Object { [string]::IsNullOrEmpty($_.Notes) }

    foreach ($app in $appRegs) {
        Write-Host "Updating app registration $($app.Id) with the default note template..." -ForegroundColor Cyan
        try {
            Update-MgApplication -ApplicationId $app.Id -Notes $defaultNote
            Write-Host "Successfully updated $($app.Id).`n" -ForegroundColor Green
        }
        catch {
            Write-Host "Error updating $($app.Id): $_" -ForegroundColor Red
        }
    }
}

main
