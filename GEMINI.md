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
Execute the script directly from PowerShell:
```powershell
.\aadtester.ps1
```
The script will interactively prompt for:
1. **Option Selection**: Choose between Graph PowerShell module or REST API approach.
2. **Admin Credentials**: UPN and Password.
3. **Target User UPN** and (depending on option) **Group Name** or **RuleWord/Department**.

## Development Conventions

- **Module Loading**: The script uses `-Force` when importing `Az.Accounts` and `Az.Resources` to avoid potential DLL conflicts.
- **Authentication**: Uses `PSCredential` and `Connect-AzAccount -Credential` for non-interactive login within the script flow (after password entry).
- **Context Management**: Clears existing Azure contexts before connecting to ensure a fresh session.
- **Output**: Uses `Write-Host` with colors for status updates and error reporting.
- **Error Handling**: Implements `try-catch` blocks to capture and display authentication or query errors.
