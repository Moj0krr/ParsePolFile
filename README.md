## Invoke-ParsePolFile

Invoke-ParsePolFile 用来解析组策略编辑器生成的 pol 格式文件

#### 使用方法

```powerhshell
. .\Invoke-ParsePolFile.ps1
Invoke-ParesePolFile -Path C:\Registry.pol
```

#### 参考

[Registry Policy File Format](https://docs.microsoft.com/en-us/previous-versions/windows/desktop/policy/registry-policy-file-format)

[Registry Policy Message Syntax](https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-gpreg/5c092c22-bf6b-4e7f-b180-b20743d368f5)

[GPRegistryPolicyParser](https://github.com/PowerShell/GPRegistryPolicyParser)
