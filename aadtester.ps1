# --- Azure AD Quick Tester ---
# A simplified, visually-guided CLI for Azure AD queries.

Clear-Host
Write-Host "🚀 Azure AD Tester (CLI)" -ForegroundColor Cyan
Write-Host "Helping you connect and query simply.`n" -ForegroundColor Gray

# 1. Setup & Dependencies
Write-Host "📦 Loading Azure modules..." -NoNewline -ForegroundColor Yellow
Import-Module Az.Accounts -Force
Import-Module Az.Resources -Force
Write-Host " Done!" -ForegroundColor Green

# 2. Input Section (Chunked for Focus)
Write-Host "`n🔑 Step 1: Authentication" -ForegroundColor Cyan
$adminUpn = Read-Host "   👉 Enter Admin Email (UPN)"
$adminPass = Read-Host "   👉 Enter Admin Password" -AsSecureString

Write-Host "`n🔍 Step 2: Target" -ForegroundColor Cyan
$targetUpn = Read-Host "   👉 Enter User Email to check"

# 3. Connection Phase
Write-Host "`n⚡ Connecting to Azure... " -ForegroundColor Yellow -NoNewline
try {
    # Create credentials
    $cred = New-Object System.Management.Automation.PSCredential($adminUpn, $adminPass)
    
    # Clean and Connect
    Clear-AzContext -Scope CurrentUser -Force -ErrorAction SilentlyContinue
    Connect-AzAccount -Credential $cred | Out-Null
    Write-Host "Success! ✅" -ForegroundColor Green
    
    # 4. Query Phase
    Write-Host "`n🕵️  Searching for: $targetUpn ..." -ForegroundColor Yellow
    
    $adUser = Get-AzADUser -UserPrincipalName $targetUpn -ErrorAction SilentlyContinue
    
    if ($adUser) {
        Write-Host "`n✨ User Found! Here is the breakdown:" -ForegroundColor Green
        Write-Host "---------------------------------------" -ForegroundColor Gray
        
        # Focus on key info first (ADHD Friendly: don't overwhelm)
        [PSCustomObject]@{
            "Display Name"    = $adUser.DisplayName
            "User Principal"  = $adUser.UserPrincipalName
            "Object ID"       = $adUser.Id
            "Account Status"  = if ($adUser.AccountEnabled) { "✅ Enabled" } else { "❌ Disabled" }
            "User Type"       = $adUser.UserType
        } | Format-List
        
        Write-Host "---------------------------------------" -ForegroundColor Gray
        
        # Offer more details if needed
        $showAll = Read-Host "`n❓ Show all technical details? (y/n)"
        if ($showAll -eq 'y') {
            Write-Host "`n📋 Full Details Dump:" -ForegroundColor Cyan
            $adUser | Format-List *
        }
    } else {
        Write-Host "`n❌ User Not Found." -ForegroundColor Red
        Write-Host "Tip: Double-check the spelling or your permissions." -ForegroundColor Gray
    }
}
catch {
    Write-Host "`n💥 Something went wrong:" -ForegroundColor Red
    Write-Host "   $($_.Exception.Message)" -ForegroundColor White
}

# 5. Exit
Write-Host "`n🏁 Task complete." -ForegroundColor Cyan
Write-Host "Press Enter to close this window..." -ForegroundColor Gray
Read-Host | Out-Null
