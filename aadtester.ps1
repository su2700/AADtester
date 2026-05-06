Write-Host "--- Azure AD Tester (CLI) ---" -ForegroundColor Cyan

# 强制加载最新版的 Az 模块，避免 DLL 冲突问题
Import-Module Az.Accounts -Force
Import-Module Az.Resources -Force

$adminUpn = Read-Host "Enter Admin User Principal ID (e.g. admin@domain.com)"
$adminPass = Read-Host "Enter Admin Password"
$targetUpn = Read-Host "Enter Target User Principal ID to query"

Write-Host "`nConnecting to Azure... Please wait." -ForegroundColor Yellow

try {
    # 按照你要求的方式转换为 SecureString
    $pass = ConvertTo-SecureString $adminPass -AsPlainText -Force
    
    # 创建凭据
    $cred = New-Object System.Management.Automation.PSCredential($adminUpn, $pass)
    
    # 清理可能残留的旧上下文
    Clear-AzContext -Scope CurrentUser -Force -ErrorAction SilentlyContinue
    
    # 登录 Azure
    Connect-AzAccount -Credential $cred | Out-Null
    Write-Host "Connected to Azure successfully!" -ForegroundColor Green
    
    Write-Host "`nQuerying Target User: $targetUpn ..." -ForegroundColor Yellow
    
    # 查询目标用户
    $adUser = Get-AzADUser -UserPrincipalName $targetUpn
    
    if ($adUser) {
        Write-Host "`n--- User Details ---" -ForegroundColor Cyan
        $adUser | Format-List *
    } else {
        Write-Host "User not found or you don't have permission to read." -ForegroundColor Red
    }
}
catch {
    Write-Host "`nError occurred:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

Write-Host "`nPress Enter to exit..."
Read-Host | Out-Null
