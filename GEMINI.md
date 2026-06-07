# Azure AD Tester (CLI)

A simple PowerShell-based command-line tool to verify Azure AD (Microsoft Entra ID) connectivity and query user information using the Azure PowerShell (`Az`) module.

## Project Overview

- **Purpose**: Authenticate with Azure using administrator credentials and retrieve details for a specific target user.
- **Main Technology**: PowerShell.
- **Dependencies**: 
  - `Az.Accounts` module
  - `Az.Resources` module
  - `Microsoft.Graph` module

## Building and Running

### Prerequisites
Ensure you have the required PowerShell modules installed:
```powershell
Install-Module -Name Az -AllowClobber -Scope CurrentUser
Install-Module -Name Microsoft.Graph -AllowClobber -Scope CurrentUser
```

### Running the Tool
Execute either script directly from PowerShell:
```powershell
.\aadtester.ps1
# OR
.\tenant-info.ps1
```
#### `aadtester.ps1` (Multi-Purpose Tester)
The script will interactively prompt for:
1. **Option Selection**: 
   - Option 1: Graph PowerShell Module (Update Department & Verify AU)
   - Option 2: REST API approach (Full Group Test)
   - Option 3: Dynamic Group Membership (Flag Hunter)
2. **Admin Credentials**: UPN and Password.
3. **Target User UPN**, **Group Name**, and **RuleWord/Department** (depending on option).

#### `tenant-info.ps1` (Tenant & Federation Discovery)
This lightweight tool uses public discovery endpoints to:
1. **Prompt for a UPN** (No password or authentication required).
2. **Output the Tenant/Brand Name**.
3. **Show Federation Status** (Managed vs. Federated).
4. **Note**: This script does not require the `Az` or `Microsoft.Graph` modules.

## Development Conventions

- **Module Loading**: The script uses `-Force` when importing `Az.Accounts` and `Az.Resources` to avoid potential DLL conflicts.
- **Authentication**: Uses `PSCredential` and `Connect-AzAccount -Credential` for non-interactive login within the script flow (after password entry).
- **Context Management**: Clears existing Azure contexts before connecting to ensure a fresh session.
- **Output**: Uses `Write-Host` with colors for status updates and error reporting.
- **Error Handling**: Implements `try-catch` blocks to capture and display authentication or query errors.
