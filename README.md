# Azure AD Tester (CLI)

A simple PowerShell-based command-line tool to verify Azure AD (Microsoft Entra ID) connectivity and query user information.

## Overview

This tool allows you to:
- Authenticate with Azure using administrator credentials.
- Retrieve and display comprehensive details for a specific user in the directory.
- Verify that your environment can successfully connect to Azure AD services via the PowerShell `Az` module.

## Prerequisites

- **PowerShell**: Windows PowerShell 5.1 or PowerShell Core 6+.
- **Azure PowerShell Module**: You must have the `Az` module installed. You can install it by running the following command in an elevated PowerShell session:

  ```powershell
  Install-Module -Name Az -AllowClobber -Scope CurrentUser
  ```

## Usage

1.  Clone or download this repository.
2.  Open a PowerShell terminal and navigate to the project directory.
3.  Run the script:
    ```powershell
    .\aadtester.ps1
    ```
4.  Follow the interactive prompts:
    - **Admin User Principal ID**: The UPN (email) of an account with directory read permissions.
    - **Admin Password**: The password for the admin account.
    - **Target User Principal ID**: The UPN of the user you want to query.

## Features

- **Forced Module Loading**: Automatically imports necessary `Az` modules with `-Force` to prevent DLL conflicts.
- **Session Cleanup**: Clears existing Azure contexts before starting to ensure a clean connection.
- **Detailed Output**: Displays all available attributes for the target user.
- **Error Handling**: Provides clear feedback if authentication fails or the user is not found.
