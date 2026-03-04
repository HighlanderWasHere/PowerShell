# ===============================
# Create Azure AD Groups by Store
# (AzureAD module only)
# ===============================

# --- SETTINGS ---
$InputCsvPath  = "\\contoso.local\departments\IT\Scripts\Input\azure_id_request.csv"      # <-- update this path
$OutputCsvPath = "\\contoso.local\departments\IT\Scripts\Output\AzureGroupsAdded.csv"    # <-- optional output name
$GroupPrefix   = "locations."     # prefix for group names
$StoreColumn   = "Store Number"   # column header in your CSV

# --- Connect to Azure AD ---
if (-not (Get-Module -ListAvailable -Name AzureAD)) {
    Write-Host "Installing AzureAD module..." -ForegroundColor Yellow
    Install-Module AzureAD -Scope CurrentUser -Force
}
Import-Module AzureAD
Connect-AzureAD

# --- Load CSV ---
if (-not (Test-Path $InputCsvPath)) { throw "CSV not found at $InputCsvPath" }

$rows = Import-Csv -Path $InputCsvPath
if (-not $rows) { throw "No rows found in CSV." }

if ($rows[0].PSObject.Properties.Name -notcontains $StoreColumn) {
    throw "Column '$StoreColumn' not found. Columns: $($rows[0].PSObject.Properties.Name -join ', ')"
}

# --- Prepare results array ---
$results = @()

# --- Process each row ---
foreach ($row in $rows) {

    $storeNumber = ($row.$StoreColumn).ToString().Trim()
    if (-not $storeNumber) {
        Write-Host "Skipping empty store number..." -ForegroundColor DarkYellow
        continue
    }

    # Clean up Excel-style numbers like 921.0 -> 921
    if ($storeNumber -match '^\d+\.0$') {
        $storeNumber = $storeNumber -replace '\.0$',''
    }

    $displayName = "$GroupPrefix$storeNumber"

    # MailNickname must be letters/numbers/underscore only
    $mailNick = ($displayName -replace '[^\w]','_')

    # Check if group already exists
    $existingGroup = Get-AzureADGroup -Filter "DisplayName eq '$displayName'" -ErrorAction SilentlyContinue

    if ($existingGroup) {
        Write-Host "Group already exists: $displayName" -ForegroundColor Cyan
        $results += [pscustomobject]@{
            "Group Name"          = $storeNumber
            "Location Group Name" = $displayName
            "Created On"          = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            "Status"              = "Exists"
            "Azure AD Group ID"   = $existingGroup.ObjectId
        }
        continue
    }

    try {
        $newGroup = New-AzureADGroup `
            -DisplayName $displayName `
            -MailEnabled $false `
            -SecurityEnabled $true `
            -MailNickname $mailNick

        Write-Host "Created group: $displayName" -ForegroundColor Green
        $results += [pscustomobject]@{
            "Group Name"          = $storeNumber
            "Location Group Name" = $displayName
            "Created On"          = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            "Status"              = "Created"
            "Azure AD Group ID"   = $newGroup.ObjectId
        }
    }
    catch {
        Write-Host "Error creating group ${displayName}: $($_.Exception.Message)" -ForegroundColor Red
        $results += [pscustomobject]@{
            "Group Name"          = $storeNumber
            "Location Group Name" = $displayName
            "Created On"          = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            "Status"              = "Error"
            "Azure AD Group ID"   = ""
        }
    }
}

# --- Optional: write results to CSV ---
# $results | Export-Csv -Path $OutputCsvPath -NoTypeInformation
