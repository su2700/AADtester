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
    Import-Module Microsoft.Graph -Force -ErrorAction Stop
    Write-Host " Done!" -ForegroundColor Green
} catch {
    Write-Host "`n[X] Error: Missing required PowerShell modules." -ForegroundColor Red
    Write-Host "    Please ensure Az and Microsoft.Graph modules are installed:" -ForegroundColor Yellow
    Write-Host "    Install-Module -Name Az -Scope CurrentUser -AllowClobber -Force" -ForegroundColor White
    Write-Host "    Install-Module -Name Microsoft.Graph -Scope CurrentUser -AllowClobber -Force" -ForegroundColor White
    Write-Host "`nPress Enter to close this window..." -ForegroundColor Gray
    Read-Host | Out-Null
    return
}

# 2. Option Selection
Write-Host "`n[!] Select an Option:" -ForegroundColor Cyan
Write-Host "   1. graph PowerShell module (Update Department & Verify AU)"
Write-Host "   2. REST API approach (Full Group Test)"
$option = Read-Host "   > Choice (1 or 2)"

if ($option -eq "1") {
    Write-Host "`n[!] Option 1: Graph PowerShell Module" -ForegroundColor Cyan
    $adminUpn = Read-Host "   > Enter Admin Email (UPN)"
    $adminPass = Read-Host "   > Enter Admin Password" -AsSecureString
    $targetUpn = Read-Host "   > Enter User Email to update"
    $ruleWord = Read-Host "   > Enter RuleWord (Department)"

    Write-Host "`n[~] Connecting..." -ForegroundColor Yellow
    try {
        $cred = New-Object System.Management.Automation.PSCredential($adminUpn, $adminPass)
        Clear-AzContext -Scope CurrentUser -Force -ErrorAction SilentlyContinue
        Connect-AzAccount -Credential $cred | Out-Null
        
        $token = Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com"
        Connect-MgGraph -AccessToken $token.Token | Out-Null
        Write-Host "   [V] Connected to Azure and Graph!" -ForegroundColor Green

        Write-Host "`n[+] Updating User Department to: $ruleWord ..." -ForegroundColor Yellow
        Set-AzADUser -UPNOrObjectId $targetUpn -Department $ruleWord
        Write-Host "   [V] Department updated successfully!" -ForegroundColor Green

        # 4. Verification Phase (Administrative Units)
        Write-Host "`n[?] Checking Administrative Unit membership for: $targetUpn ..." -ForegroundColor Yellow
        $auMemberships = Get-MgUserMemberOf -UserId $targetUpn -All | Where-Object { $_.AdditionalProperties["@odata.type"] -eq "#microsoft.graph.administrativeUnit" }
        
        if ($auMemberships) {
            Write-Host "   [V] User is a member of the following Administrative Units:" -ForegroundColor Green
            $auMemberships | Select-Object Id, @{N="DisplayName"; E={$_.AdditionalProperties["displayName"]}} | Format-Table -AutoSize
            
            $auId = Read-Host "`n   > Enter AU ID to list all members (or press Enter to skip)"
            if ($auId) {
                Write-Host "`n[?] Listing members for Administrative Unit: $auId ..." -ForegroundColor Yellow
                Get-MgDirectoryAdministrativeUnitMember -AdministrativeUnitId $auId | Format-List
            }
        } else {
            Write-Host "   [-] No Administrative Unit memberships found for this user." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "`n[X] Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}
else {
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
}

# 7. Exit
Write-Host "`n[!] Task complete." -ForegroundColor Cyan
Write-Host "Press Enter to close this window..." -ForegroundColor Gray
Read-Host | Out-Null
