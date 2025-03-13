# Connect to Microsoft Graph (Make sure you have the necessary permissions)
Connect-MgGraph -Scopes "Application.ReadWrite.All" -TenantId "e712b66c-2cb8-430e-848f-dbab4beb16df"

# Define your App ID
$appId = "cd98c0a4-8d2d-45b9-a176-84244c88f4fd"

# Step 1: Get the current application manifest
$appManifest = Get-MgApplication -ApplicationId $appId
$appManifest.RequiredResourceAccess | Format-Table -Property ResourceAppId, ResourceAccess

# Step 2: Check if RequiredResourceAccess exists and filter out Scope-type ResourceAccess
if ($appManifest.RequiredResourceAccess) {
    foreach ($requiredResource in $appManifest.RequiredResourceAccess) {
        # Filter out all ResourceAccess of Type 'Scope'
        $requiredResource.ResourceAccess = $requiredResource.ResourceAccess | Where-Object { $_.Type -ne 'Scope' }

        # If no ResourceAccess left after filtering, remove this RequiredResourceAccess
        if ($requiredResource.ResourceAccess.Count -eq 0) {
            # Remove the entire RequiredResourceAccess block if no ResourceAccess remains
            $appManifest.RequiredResourceAccess = $appManifest.RequiredResourceAccess | Where-Object { $_ -ne $requiredResource }
        }
    }
}

# Step 3: Update the application manifest in Azure AD if there are changes
if ($appManifest.RequiredResourceAccess.Count -gt 0) {
    # Apply the updated manifest
    Update-MgApplication -ApplicationId $appId -RequiredResourceAccess $appManifest.RequiredResourceAccess
    $appManifest.RequiredResourceAccess | Format-Table -Property ResourceAppId, ResourceAccess
    Write-Host "Application manifest updated successfully."
} else {
    Write-Host "No Scope-based ResourceAccess found. No changes made."
}

Disconnect-MgGraph | Out-Null
