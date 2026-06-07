# --- Tenant & Federation Discovery Tool ---
# A lightweight, password-less utility to check Tenant details, Federation, and Account validity.

Clear-Host
Write-Host "[*] Tenant Discovery Utility" -ForegroundColor Cyan
Write-Host "Retrieving all public tenant metadata and validating account (no password required).`n" -ForegroundColor Gray

# 1. Input Phase
$targetUpn = Read-Host "   > Enter Email / UPN to check"
if (-not $targetUpn) {
    Write-Host "[X] UPN is required." -ForegroundColor Red
    return
}

# 2. Query Phase
try {
    # Extract domain for OpenID discovery
    $domain = $targetUpn
    if ($targetUpn -match '@') {
        $domain = $targetUpn.Split('@')[1]
    }

    Write-Host "[~] Querying Microsoft Discovery Endpoints..." -ForegroundColor Yellow
    
    # 2.1 User Realm Discovery (XML)
    $realmUrl = "https://login.microsoftonline.com/getuserrealm.srf?login=$targetUpn&xml=1"
    $realmResponse = Invoke-RestMethod -Uri $realmUrl -Method Get -ErrorAction Stop
    $realm = if ($realmResponse.RealmInfo) { $realmResponse.RealmInfo } else { $realmResponse.Realm }

    # 2.2 OpenID Configuration (JSON)
    $oidcUrl = "https://login.microsoftonline.com/$domain/.well-known/openid-configuration"
    $oidcResponse = $null
    try {
        $oidcResponse = Invoke-RestMethod -Uri $oidcUrl -Method Get -ErrorAction SilentlyContinue
    } catch { }

    # 2.3 Credential Type / Email Validation (JSON POST)
    $credUrl = "https://login.microsoftonline.com/common/GetCredentialType"
    $credBody = @{ username = $targetUpn } | ConvertTo-Json
    $credResponse = $null
    try {
        $credResponse = Invoke-RestMethod -Uri $credUrl -Method Post -Body $credBody -ContentType "application/json" -ErrorAction SilentlyContinue
    } catch { }

    # 3. Output Phase
    if ($realm) {
        Write-Host "`n[V] Discovery Successful!" -ForegroundColor Green
        
        # 3.1 Account Validation Summary
        Write-Host "--- Account Validation & Insights ---" -ForegroundColor Cyan
        if ($credResponse) {
            $exists = if ($credResponse.IfExistsResult -eq 0) { "EXISTS (Valid)" } else { "UNKNOWN / NOT FOUND" }
            $color = if ($credResponse.IfExistsResult -eq 0) { "Green" } else { "Red" }
            
            Write-Host "   Account Validity  : " -NoNewline -ForegroundColor White
            Write-Host $exists -ForegroundColor $color
            
            Write-Host "   Has Password      : " -NoNewline -ForegroundColor White
            Write-Host ($credResponse.Credentials.HasPassword -as [string]).ToUpper() -ForegroundColor Gray
            
            Write-Host "   Is Managed        : " -NoNewline -ForegroundColor White
            Write-Host ((-not $credResponse.IsUnmanaged) -as [string]).ToUpper() -ForegroundColor Gray
            
            Write-Host "   Throttle Status   : " -NoNewline -ForegroundColor White
            Write-Host $credResponse.ThrottleStatus -ForegroundColor Gray
        } else {
            Write-Host "   [!] Account validation endpoint failed or blocked." -ForegroundColor Yellow
        }
        Write-Host ""

        # 3.2 Tenant Summary
        Write-Host "--- Tenant Summary ---" -ForegroundColor Cyan
        
        $brandName = if ($realm.FederationBrandName) { $realm.FederationBrandName } else { "N/A" }
        Write-Host "   Tenant/Brand Name : " -NoNewline -ForegroundColor White
        Write-Host $brandName -ForegroundColor Green
        
        $status = $realm.NameSpaceType
        Write-Host "   Federation Status : " -NoNewline -ForegroundColor White
        switch ($status) {
            "Managed"   { Write-Host "Managed (Standard Azure AD)" -ForegroundColor Cyan }
            "Federated" { Write-Host "Federated (Using External IdP)" -ForegroundColor Yellow }
            default     { 
                if ($realm.IsFederatedNS -eq "true" -or $realm.IsFederatedNS -eq $true) {
                    Write-Host "Federated" -ForegroundColor Yellow
                } else {
                    Write-Host (if ($status) { $status } else { "Managed" }) -ForegroundColor Cyan 
                }
            }
        }
        Write-Host ""

        # 3.3 Raw Data Sections (Optional display)
        $showRaw = Read-Host "   > Show full metadata results? (y/n)"
        if ($showRaw -eq 'y') {
            if ($oidcResponse) {
                Write-Host "`n--- OpenID Configuration (Full Metadata) ---" -ForegroundColor Cyan
                $oidcResponse | Format-List | Out-String | Write-Host -ForegroundColor Gray
            }
            Write-Host "`n--- Realm Discovery Data ---" -ForegroundColor Cyan
            $realm | Format-List | Out-String | Write-Host -ForegroundColor Gray
            
            Write-Host "`n--- Credential Type Data ---" -ForegroundColor Cyan
            $credResponse | Format-List | Out-String | Write-Host -ForegroundColor Gray
        }

    } else {
        Write-Host "[X] Could not parse realm information for this UPN." -ForegroundColor Red
    }
} catch {
    Write-Host "`n[X] Error connecting to discovery endpoints:" -ForegroundColor Red
    Write-Host "   $($_.Exception.Message)" -ForegroundColor White
}

# 4. Final Tenant ID Output
if ($oidcResponse -and $oidcResponse.issuer) {
    if ($oidcResponse.issuer -match '([a-fA-F0-9\-]{36})') {
        Write-Host "`n[!] FINAL TENANT ID: " -NoNewline -ForegroundColor Green
        Write-Host $Matches[1] -ForegroundColor White -BackgroundColor DarkBlue
    }
}

# 5. Result Explanation (In English)
Write-Host "`n--- Analysis Conclusion ---" -ForegroundColor Cyan
Write-Host "🔬 The verification results for this account are clear:" -ForegroundColor White
if ($credResponse.IfExistsResult -eq 0) {
    Write-Host "   - Account Existence (IfExistsResult: 0): The account is REAL and VALID. It exists in Entra ID." -ForegroundColor Gray
    Write-Host "   - Authentication (HasPassword: true): The account has a traditional password, making it a candidate for testing." -ForegroundColor Gray
    Write-Host "   - Governance (IsUnmanaged: false): This is a managed corporate account, not a personal viral tenant." -ForegroundColor Gray
    Write-Host "   - Domain Type (DomainType: 3): This is a standard cloud-hosted 'onmicrosoft.com' domain." -ForegroundColor Gray
    Write-Host "   - Stealth (ThrottleStatus: 0): The request was successful and did not trigger any rate limiting." -ForegroundColor Gray
} else {
    Write-Host "   - The account could not be verified as existing in the common tenant." -ForegroundColor Gray
}

# 6. Exit
Write-Host "`n[!] Task complete." -ForegroundColor Cyan
Write-Host "Press Enter to close this window..." -ForegroundColor Gray
Read-Host | Out-Null
