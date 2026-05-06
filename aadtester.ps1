# --- Azure AD Quick Tester ---
# A simplified, visually-guided CLI for Azure AD & Graph queries.

Clear-Host
Write-Host "[*] Azure AD & Graph Tester" -ForegroundColor Cyan
Write-Host "Helping you connect, query, and test dynamic groups.`n" -ForegroundColor Gray

# 1. Setup & Dependencies
Write-Host "[+] Loading Modules (Az & Graph)..." -NoNewline -ForegroundColor Yellow
try {
    Import-Module Az.Accounts -Force -ErrorAction Stop
    Import-Module Az.Resources -Force -ErrorAction Stop
    Write-Host " Done!" -ForegroundColor Green
} catch {
    Write-Host "`n[X] Error: Missing required PowerShell modules." -ForegroundColor Red
    Write-Host "    Please run the following command to install them:" -ForegroundColor Yellow
    Write-Host "    Install-Module -Name Az -Scope CurrentUser -AllowClobber -Force" -ForegroundColor White
    Write-Host "`nPress Enter to close this window..." -ForegroundColor Gray
    Read-Host | Out-Null
    return
}

# 2. Input Section (Chunked for Focus)
Write-Host "`n[!] Step 1: Authentication" -ForegroundColor Cyan
$adminUpn = Read-Host "   > Enter Admin Email (UPN)"
$adminPass = Read-Host "   > Enter Admin Password" -AsSecureString

Write-Host "`n[!] Step 2: Target & Group" -ForegroundColor Cyan
$targetUpn = Read-Host "   > Enter User Email to update"
$groupName = Read-Host "   > Enter Group Name to search"
$deptWord  = Read-Host "   > Enter Department Name (Dynamic Rule Word)"

# 3. Connection Phase
Write-Host "`n[~] Connecting to Azure & Graph... " -ForegroundColor Yellow
try {
    # Az Connection
    $cred = New-Object System.Management.Automation.PSCredential($adminUpn, $adminPass)
    Clear-AzContext -Scope CurrentUser -Force -ErrorAction SilentlyContinue
    Connect-AzAccount -Credential $cred | Out-Null
    Write-Host "   [V] Azure connected!" -ForegroundColor Green
    
    # Graph API Setup (via Az Token)
    $token = (Get-AzAccessToken -ResourceTypeName MSGraph).Token
    $headers = @{ Authorization = "Bearer $token" }
    
    # 4. Search Group Phase
    Write-Host "`n[?] Searching for Group: $groupName ..." -ForegroundColor Yellow
    $groupUri = "https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '$groupName'"
    $groupResponse = Invoke-RestMethod -Uri $groupUri -Headers $headers -Method Get -ErrorAction Stop
    $targetGroup = $groupResponse.value | Select-Object -First 1
    
    if ($targetGroup) {
        Write-Host "   [V] Group Found! (ID: $($targetGroup.id))" -ForegroundColor Green
    } else {
        Write-Host "   [X] Group '$groupName' not found." -ForegroundColor Red
        throw "Target group not found."
    }

    # 5. Update User Phase
    Write-Host "`n[+] Updating User Department to: $deptWord ..." -ForegroundColor Yellow
    Set-AzADUser -UPNOrObjectId $targetUpn -Department $deptWord
    Write-Host "   [V] Department updated successfully!" -ForegroundColor Green

    # 6. Verification Phase
    Write-Host "`n[i] Note: Dynamic membership usually takes 2-5 minutes to sync." -ForegroundColor Gray
    $checkNow = Read-Host "   (?) Try to verify membership now? (y/n)"
    
    if ($checkNow -eq 'y') {
        Write-Host "`n[?] Checking members for Group: $groupName ..." -ForegroundColor Yellow
        $membersUri = "https://graph.microsoft.com/v1.0/groups/$($targetGroup.id)/members"
        $membersResponse = Invoke-RestMethod -Uri $membersUri -Headers $headers -Method Get -ErrorAction Stop
        $isMember = $membersResponse.value | Where-Object { $_.userPrincipalName -eq $targetUpn -or $_.id -eq $targetUpn }
        
        if ($isMember) {
            Write-Host "   [!] Success! User is now a member of the group." -ForegroundColor Green
        } else {
            Write-Host "   [-] User not found in group yet. (Still syncing?)" -ForegroundColor Yellow
        }
    }
}
catch {
    Write-Host "`n[X] Something went wrong:" -ForegroundColor Red
    Write-Host "   $($_.Exception.Message)" -ForegroundColor White
}

# 7. Exit
Write-Host "`n[!] Task complete." -ForegroundColor Cyan
Write-Host "Press Enter to close this window..." -ForegroundColor Gray
Read-Host | Out-Null
