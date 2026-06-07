# Azure AD & Entra ID Tester (CLI)

A set of PowerShell-based tools to verify Azure AD (Microsoft Entra ID) connectivity, discover tenant metadata, and validate accounts.

## Overview

This project provides two primary utilities for interacting with and investigating Entra ID environments:

1.  **`aadtester.ps1`**: An authenticated tool for administrators to manage users, verify Administrative Units, and test Dynamic Group memberships.
2.  **`tenant-info.ps1`**: A password-less discovery utility that retrieves comprehensive tenant metadata and validates account existence using public Microsoft endpoints.

---

## 🛠 Tools

### 1. Tenant Discovery Utility (`tenant-info.ps1`)
A lightweight, non-authenticated tool for reconnaissance and environment validation.

*   **Capabilities**:
    *   **Account Validation**: Verifies if a UPN exists using `GetCredentialType`.
    *   **Security Insights**: Identifies if an account is managed, has a password, and its domain type.
    *   **Tenant Metadata**: Retrieves Tenant Brand Name and Federation Status (Managed vs. Federated).
    *   **Advanced Discovery**: Extracts the **Tenant ID (GUID)** and Regional Scope via OpenID Configuration.
*   **Usage**:
    ```powershell
    .\tenant-info.ps1
    ```
*   **No Dependencies**: Does not require `Az` or `Microsoft.Graph` modules.

### 2. Multi-Purpose Tester (`aadtester.ps1`)
An authenticated tool for deeper directory interaction.

*   **Capabilities**:
    *   **Update Department**: Modify user attributes to trigger dynamic group rules.
    *   **Verify AU**: Check Administrative Unit memberships.
    *   **REST & Graph Testing**: Validates API connectivity and dynamic group sync status.
*   **Usage**:
    ```powershell
    .\aadtester.ps1
    ```
*   **Dependencies**: Requires `Az` and `Microsoft.Graph` modules.

---

## 🚀 Prerequisites

### For `tenant-info.ps1`
- **PowerShell**: Windows PowerShell 5.1 or PowerShell Core 6+.
- **Internet Access**: Must be able to reach `login.microsoftonline.com`.

### For `aadtester.ps1`
- **Modules**: Install the required PowerShell modules:
  ```powershell
  Install-Module -Name Az -AllowClobber -Scope CurrentUser
  Install-Module -Name Microsoft.Graph -AllowClobber -Scope CurrentUser
  ```

---

## 📋 Analysis Interpretation (Discovery Tool)

When using `tenant-info.ps1`, the output provides key security indicators:

- **IfExistsResult: 0**: The account is **REAL and VALID**.
- **HasPassword: true**: The account supports traditional password authentication.
- **IsUnmanaged: false**: The account is governed by a corporate tenant (Managed).
- **Tenant ID**: The unique GUID identifying the organization's directory.
- **Federation Status**: Indicates if the tenant uses standard Azure authentication (Managed) or an external provider like AD FS or Okta (Federated).

## Development Conventions

- **Security First**: Discovery tools use public-facing endpoints and require no credentials.
- **Clean Sessions**: Scripts automatically clear existing Azure contexts to ensure reliable results.
- **Verbose Feedback**: Color-coded output for status, errors, and critical identifiers.
