<#
.SYNOPSIS
Reads and parses a .pol file.

.DESCRIPTION
Reads a .pol file, parses it and returns an array of Group Policy registry settings.

.PARAMETER Path
Specifies the path to the .pol file.

.EXAMPLE
C:\PS> Invoke-ParsePolFile -Path "C:\Registry.pol"

#>


function Invoke-ParesePolFile {
    [CmdletBinding()]

    param (
        [string]
        $Path
    )


    Enum RegType {
        REG_SZ = 1 # Unicode null terminated string
        REG_EXPAND_SZ = 2 # Unicode null terminated string (with environmental variable references)
        REG_BINARY = 3 # Data in the Data field to be interpreted as an octet stream
        REG_DWORD = 4 # a 32-bit number in little-endian format
        REG_DWORD_BIG_ENDIAN = 5 # a 32-bit number in big-endian format
        REG_MULTI_SZ = 7 # Multiple Unicode strings, delimited by \0, terminated by \0\0
        REG_QWORD = 11 # a 64-bit number in little-endian format
    }

    [byte[]] $PolicyContentBytes = Get-Content $Path -Raw -Encoding Byte

    # 4 bytes are the signature PReg
    $signature = [System.Text.Encoding]::ASCII.GetString($PolicyContentBytes[0..3])
    if ($signature -ne 'PReg') {throw 'Invalid header'}

    # 4 bytes are the version
    $version = [System.BitConverter]::ToInt32($PolicyContentBytes, 4)
    Write-Verbose "Version: $version"

    # Start processing at byte 8
    $cursor = 8
    [Array] $RegistryPolicies = @()

    while ($cursor -lt $PolicyContentBytes.Length) {
        #  the left square bracket [
        $leftbracket = [System.BitConverter]::ToChar($PolicyContentBytes, $cursor)
        if ($leftbracket -ne '[') {throw 'Missing the left bracket'}
        $cursor += 2

        # key string will continue until the ;
        $key = ''
        while ($true) {
            $char = [System.BitConverter]::ToChar($PolicyContentBytes, $cursor)
            if ($char -eq ';') {
                break
            } else {
                $key += $char
                $cursor += 2
            }
        }
        $cursor += 2 # Skip ;

        # value string will continue until the ; 
        $value = ''
        while ($true) {
            $char = [System.BitConverter]::ToChar($PolicyContentBytes, $cursor)
            if ($char -eq ';') {
                break
            } else {
                $value += $char
                $cursor += 2
            }
        }
        $cursor += 2 # Skip ;

        # type DWORD will continue until the ;
        $type = 0
        $type = [System.BitConverter]::ToInt32($PolicyContentBytes, $cursor)
        $cursor += 4
        $cursor += 2 # Skip ;

        # size DWORD will continue until the ;
        $size = 0
        $size = [System.BitConverter]::ToInt32($PolicyContentBytes, $cursor)
        $cursor += 4
        $cursor += 2 # Skip ;

        # data
        $data = ''
        $typeString = ''
        if ($size -gt 0) {
            if ($type -eq [RegType]::REG_SZ) {
                $data = [System.Text.Encoding]::Unicode.GetString($PolicyContentBytes[($cursor)..($cursor+$size-1)])
                $typeString = [RegType]::REG_SZ
            }

            if ($type -eq [RegType]::REG_EXPAND_SZ) {
                $data = [System.Text.Encoding]::Unicode.GetString($PolicyContentBytes[($cursor)..($cursor+$size-1)])
                $typeString = [RegType]::REG_EXPAND_SZ
            }

            if ($type -eq [RegType]::REG_MULTI_SZ) {
                $data = [System.Text.Encoding]::Unicode.GetString($PolicyContentBytes[($cursor)..($cursor+$size-1)])
                $typeString = [RegType]::REG_MULTI_SZ
            }

            if ($type -eq [RegType]::REG_DWORD) {
                $data = [System.BitConverter]::ToInt32($PolicyContentBytes, $cursor)
                $typeString = [RegType]::REG_DWORD
            }

            if ($type -eq [RegType]::REG_QWORD) {
                $data = [System.BitConverter]::ToInt64($PolicyContentBytes, $cursor)
                $typeString = [RegType]::REG_QWORD
            }

            if ($type -eq [RegType]::REG_BINARY) {
                $data = $PolicyContentBytes[($cursor)..($cursor+$size-1)]
                $typeString = [RegType]::REG_BINARY
            }
        }
        $cursor += $size
        
        # the right square bracket ]
        $rightbracket = [System.BitConverter]::ToChar($PolicyContentBytes, $cursor)
        $cursor += 2
        
        $entry = ''
        $entry = "$leftbracket$key$value $typeString $data$rightbracket"
        $RegistryPolicies += $entry

    }

    return $RegistryPolicies
}
