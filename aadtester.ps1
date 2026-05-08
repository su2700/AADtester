# --- Azure AD Quick Tester ---
# A simplified, visually-guided CLI for Azure AD & Graph queries.

Clear-Host
Write-Host "[*] Azure AD & Graph Tester" -ForegroundColor Cyan
Write-Host "Helping you connect, query, and test dynamic groups.`n" -ForegroundColor Gray

# 1. Setup & Dependencies
Write-Host "[+] Checking/Loading Modules (Az & Graph)..." -NoNewline -ForegroundColor Yellow
try {
    $modules = @("Az.Accounts", "Az.Resources", "Microsoft.Graph.Authentication", "Microsoft.Graph.Users", "Microsoft.Graph.Identity.DirectoryManagement", "Microsoft.Graph.Groups")
    foreach ($m in $modules) {
        if (-not (Get-Module -Name $m -ErrorAction SilentlyContinue)) {
            Import-Module $m -Force -ErrorAction Stop
        }
    }
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
Write-Host "   1. Graph PowerShell Module (Update Department & Verify AU)"
Write-Host "   2. REST API Approach (Full Group Test)"
Write-Host "   3. Dynamic Group Membership (Flag Hunter)"
$option = Read-Host "   > Choice (1, 2, or 3)"

switch ($option) {
    "1" {
        Write-Host "`n[!] Option 1: Graph PowerShell Module" -ForegroundColor Cyan
        $adminUpn = Read-Host "   > Enter Admin Email (UPN)"
        $adminPass = Read-Host "   > Enter Admin Password" -AsSecureString
        $targetUpn = Read-Host "   > Enter User Email to update"
        $ruleWord = Read-Host "   > Enter RuleWord (Department)"

        Write-Host "`n[~] Connecting..." -ForegroundColor Yellow
        try {
            $tenantId = $adminUpn.Split('@')[1]
            $cred = New-Object System.Management.Automation.PSCredential($adminUpn, $adminPass)
            Clear-AzContext -Scope CurrentUser -Force -ErrorAction SilentlyContinue
            
            Write-Host "   [+] Logging into Tenant: $tenantId ..." -ForegroundColor Gray
            Connect-AzAccount -Credential $cred -Tenant $tenantId -ErrorAction Stop | Out-Null
            
            $token = Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com" -ErrorAction Stop
            Connect-MgGraph -AccessToken $token.Token -ErrorAction Stop | Out-Null
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
    "2" {
        Write-Host "`n[!] Option 2: REST API Approach" -ForegroundColor Cyan
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
            $tenantId = $adminUpn.Split('@')[1]
            # Az Connection
            $cred = New-Object System.Management.Automation.PSCredential($adminUpn, $adminPass)
            Clear-AzContext -Scope CurrentUser -Force -ErrorAction SilentlyContinue
            Write-Host "   [+] Logging into Tenant: $tenantId ..." -ForegroundColor Gray
            Connect-AzAccount -Credential $cred -Tenant $tenantId -ErrorAction Stop | Out-Null
            Write-Host "   [V] Azure connected!" -ForegroundColor Green
            
            # Graph API Setup (via Az Token)
            $token = (Get-AzAccessToken -ResourceTypeName MSGraph -ErrorAction Stop).Token
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
    "3" {
        Write-Host "`n[!] Option 3: Dynamic Group Membership (Flag Hunter)" -ForegroundColor Cyan
        $adminUpn = Read-Host "   > Enter Admin Email (UPN)"
        $adminPass = Read-Host "   > Enter Admin Password" -AsSecureString
        $targetUpn = Read-Host "   > Enter User Email to update (Target User)"
        $groupName = Read-Host "   > Enter Group Name to search"
        $deptWord = Read-Host "   > Enter RuleWord (Department)"

        Write-Host "`n[~] Connecting..." -ForegroundColor Yellow
        try {
            $tenantId = $adminUpn.Split('@')[1]
            $cred = New-Object System.Management.Automation.PSCredential($adminUpn, $adminPass)
            Clear-AzContext -Scope CurrentUser -Force -ErrorAction SilentlyContinue
            Write-Host "   [+] Logging into Tenant: $tenantId ..." -ForegroundColor Gray
            Connect-AzAccount -Credential $cred -Tenant $tenantId -ErrorAction Stop | Out-Null
            
            $token = (Get-AzAccessToken -ResourceTypeName MSGraph -ErrorAction Stop).Token
            Connect-MgGraph -AccessToken $token -ErrorAction Stop | Out-Null
            Write-Host "   [V] Connected to Azure and Graph!" -ForegroundColor Green

            Write-Host "`n[?] Searching for Group: $groupName ..." -ForegroundColor Yellow
            $targetGroup = Get-MgGroup -All | Where-Object {$_.DisplayName -eq $groupName}
            if ($targetGroup) {
                Write-Host "   [V] Group Found!" -ForegroundColor Green
                $targetGroup | Select-Object DisplayName, Id, Description, GroupTypes, MembershipRule | Format-List
                
                # Try to suggest the RuleWord if it's a department rule
                if ($targetGroup.MembershipRule -match 'user\.department\s+-eq\s+"([^"]+)"') {
                    $suggestedDept = $Matches[1]
                    Write-Host "   [i] Detected Dynamic Rule: Department should be '$suggestedDept'" -ForegroundColor Cyan
                    $useSuggested = Read-Host "   > Use this suggested value? (y/n)"
                    if ($useSuggested -eq 'y') { $deptWord = $suggestedDept }
                }
            } else {
                Write-Host "   [X] Group '$groupName' not found." -ForegroundColor Red
                throw "Target group not found."
            }

            Write-Host "`n[+] Updating User Department to: $deptWord ..." -ForegroundColor Yellow
            Set-AzADUser -UPNOrObjectId $targetUpn -Department $deptWord -ErrorAction Stop
            Write-Host "   [V] Department updated successfully!" -ForegroundColor Green

            Write-Host "`n[i] Note: Dynamic membership usually takes 2-5 minutes to sync." -ForegroundColor Gray
            $checkNow = Read-Host "   (?) Try to verify membership now? (y/n)"
            if ($checkNow -eq 'y') {
                Write-Host "`n[?] Checking members for Group: $($targetGroup.DisplayName) ($($targetGroup.Id)) ..." -ForegroundColor Yellow
                Get-MgGroupMember -GroupId $targetGroup.Id | Format-List
                Write-Host "`n[!] Check the Group Description above for the flag if the user has been added." -ForegroundColor Cyan
            }
        }
        catch {
            Write-Host "`n[X] Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    default {
        Write-Host "`n[X] Invalid option selected." -ForegroundColor Red
    }
}

# 7. Exit
Write-Host "`n[!] Task complete." -ForegroundColor Cyan
Write-Host "Press Enter to close this window..." -ForegroundColor Gray
Read-Host | Out-Null
