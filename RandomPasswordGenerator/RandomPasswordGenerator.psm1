Function Get-RandomPassword {
    <#
    .SYNOPSIS
        This function allows you to generate one or more random passwords.

    .DESCRIPTION
        This is a module that allows generating random passwords.
        The default length of the generated password is 15 characters and contains lower, upper case letters, numbers and special characters.
        You can change the default length and the structure of the password by using some optional parameters.

    .PARAMETER PasswordLength
        If you want to generate one or more passwords with a different length than the default one you can specify this parameter. If not specified,
        the default value is 15.

    .PARAMETER NoOfPasswords
        If you want to generate more than one random password, you can specify this parameter. If not specified, the default value is 1.

    .PARAMETER PercentLowerCaseLetters
        Use this parameter if you want to change the structure of the password. If not specified, the default value is 0.3.

    .PARAMETER PercentUpperCaseLetters
        Use this parameter if you want to change the structure of the password. If not specified, the default value is 0.3.

    .PARAMETER PercentNumbers
        Use this parameter if you want to change the structure of the password. If not specified, the default value is 0.2.

    .PARAMETER PercentCharacters
        Use this parameter if you want to change the structure of the password. If not specified, the default value is 0.2.

    .PARAMETER OpenInTextFile
        Use this parameter if you want to open the generated passwords in a *.txt file.

    .EXAMPLE
        PS> Get-RandomPassword

        This example generates 1 password of 15 characters composed of: 30% upper case letters, 30% lower case letters, 20% numbers and 20% special characters.

    .EXAMPLE
        PS> Get-RandomPassword -PasswordLength 9

        This example generates 1 password with custom number of characters (9), default percents structure.
    
    .EXAMPLE
        PS> Get-RandomPassword -PasswordLength 10 -NoOfPasswords 30 -PercentLowerCaseLetters 0.5 -PercentNumbers 0.5 -OpenInTextFile

        This example generates 30 passwords of 10 characters composed 50% of Lowercase letters and 50% numbers each. It will also create and open a temporary text file with the passwords.
     
    .EXAMPLE
        PS> Get-RandomPassword -NoOfPasswords 7000 -OpenInTextFile

        This example generates 7000 passwords with default length (15 characters) and default structure(30% UpperCase letters, 30% LowerCase letters, 20% numbers and 20% special characters. 
        Then creates and opens a *.txt file with the generated passwords. 
    
    .EXAMPLE
        PS> Get-RandomPassword -PasswordLength 10 -NoOfPasswords 1 -PercentLowerCaseLetters 0.5

        This example generates an error: if you change at least a percent, you need to input Percents that sum 1.

    .INPUTS
        None.

    .OUTPUTS
        The return Type of generated passwords is an Array of PSCustomObjects with 2 properties: PasswordId and PasswordValue.

    .LINK
        http://andreilungu.com/powershell-random-password-generator
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$False)][int]$PasswordLength = 15,
        [Parameter(Mandatory=$False)][double]$PercentLowerCaseLetters = 0.25,
        [Parameter(Mandatory=$False)][double]$PercentUpperCaseLetters = 0.25,
        [Parameter(Mandatory=$False)][double]$PercentNumbers = 0.3,
        [Parameter(Mandatory=$False)][double]$PercentCharacters = 0.2,
        [Parameter(Mandatory=$False)][int]$NoOfPasswords = 1,
        [switch]$OpenInTextFile
        )

    If(UserChangedPercentParameters -UsedParameters $PSBoundParameters) {
       if(!$PSBoundParameters.ContainsKey('PercentLowerCaseLetters')){$PercentLowerCaseLetters = 0;}
       if(!$PSBoundParameters.ContainsKey('PercentUpperCaseLetters')){$PercentUpperCaseLetters = 0;}
       if(!$PSBoundParameters.ContainsKey('PercentNumbers')){$PercentNumbers = 0;}
       if(!$PSBoundParameters.ContainsKey('PercentCharacters')){$PercentCharacters = 0;}
    }
    If(($PercentLowerCaseLetters + $PercentUpperCaseLetters + $PercentNumbers + $PercentCharacters) -ne 1) {
        throw "Sum of percents must be 1 !"
    }

    $LCaseLettersArr = @(); $UCaseLettersArr = @(); $NumbersArr = @(); $OtherCharactersArr =  @()
    $LCaseLettersArr = GetCharArr -Percent $PercentLowerCaseLetters -TypeArr:Lcase
    $UCaseLettersArr = GetCharArr -Percent $PercentUpperCaseLetters -TypeArr:Ucase
    $NumbersArr = GetCharArr -Percent $PercentNumbers -TypeArr:Num
    $OtherCharactersArr = GetCharArr -Percent $PercentCharacters -TypeArr:Char

    $TotalNoOfCharacters = $LCaseLettersArr.Count + $UCaseLettersArr.Count + $NumbersArr.Count + $OtherCharactersArr.Count
    $AllPasswords = @()
    $NoOfGroups = GetNumberOfIterations -PassLength $PasswordLength -NumberOfChars $TotalNoOfCharacters

    for($i= 0; $i -lt $NoOfPasswords; $i++) {
        $PasswordArr = @()
        for($j= 0; $j -lt $NoOfGroups; $j++) {
            $PasswordArr += GetRandomCharsArr -CharsArr $LCaseLettersArr -PasswordLength $PasswordLength -Percent $PercentLowerCaseLetters
            $PasswordArr += GetRandomCharsArr -CharsArr $UCaseLettersArr -PasswordLength $PasswordLength -Percent $PercentUpperCaseLetters
            $PasswordArr += GetRandomCharsArr -CharsArr $NumbersArr -PasswordLength $PasswordLength -Percent $PercentNumbers
            $PasswordArr += GetRandomCharsArr -CharsArr $OtherCharactersArr -PasswordLength $PasswordLength -Percent $PercentCharacters
        }
        ShowProgress -CurrentItem $i -TotalItems $NoOfPasswords
        $PassNo = $i+1
        $AllPasswords += CreatePasswordObject -PassKey "Pass$PassNo" -PassValue (($PasswordArr | Get-Random -Count $PasswordLength) -Join "")
    }

    If($OpenInTextFile) {
        CreateAndOpenTempTextFile -AllPasswords $AllPasswords
    }
    return $AllPasswords
}

Function UserChangedPercentParameters {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
        [Parameter(Mandatory=$true)][hashtable]$UsedParameters
    )
    If($UsedParameters.ContainsKey('PercentLowerCaseLetters') -or $UsedParameters.ContainsKey('PercentUpperCaseLetters') `
        -or $UsedParameters.ContainsKey('PercentNumbers') -or $UsedParameters.ContainsKey('PercentCharacters')) {
        return $true
    }
    return $false
}

Function CreateAndOpenTempTextFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][array]$AllPasswords
    )
    $tmp = New-TemporaryFile
    $AllPasswords | Format-Table -Wrap | Out-File $tmp.FullName
    Invoke-Item $tmp
}

Function GetNumberOfIterations {
    [CmdletBinding()]
    [OutputType([System.Int32])]
    param(
        [Parameter(Mandatory=$true)][int]$PassLength,
        [Parameter(Mandatory=$true)][int]$NumberOfChars
    )
    If($PassLength -gt $NumberOfChars) {
        return [int][math]::Ceiling($PassLength / $NumberOfChars)
    }
    return 1
}

Function GetCharArr {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][double]$Percent,
        [Parameter(Mandatory=$true)][ValidateSet("Lcase","Ucase","Num","Char")][String]$TypeArr
    )
    $LCaseLetters = 'a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z'
    if($Percent -gt 0) {
        If($TypeArr -eq "Ucase") {
            $UCaseLetters = $LCaseLetters.ToUpper()
            return $UCaseLetters.Split(',')
        }
        If($TypeArr -eq "Lcase") {
            return $LCaseLetters.Split(',')
        }
        If ($TypeArr -eq "Num") {
            return 0..9
        }
        If ($TypeArr -eq "Char") {
            $OtherCharacters = '!,),(,@,/,*,$,^,%,],[,<,>,?,#,=,+,-,|,~,},{'
            return $OtherCharacters.Split(',')
        }
    }
}

Function CreatePasswordObject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$PassKey,
        [Parameter(Mandatory=$true)][string]$PassValue
    )
    $TmpHash = @{}
    $TmpHash.Add('PasswordId',$PassKey)
    $TmpHash.Add('PasswordValue',$PassValue)
    $PassObj = New-Object PSObject -property $TmpHash
    return $PassObj
}

Function GetRandomCharsArr {
    [CmdletBinding()]
    param(
        [AllowEmptyCollection()][array]$CharsArr,
        [Parameter(Mandatory=$true)][int]$PasswordLength,
        [Parameter(Mandatory=$true)][double]$Percent
    )
    If($CharsArr.Count -gt 0) {
        return $CharsArr | Get-Random -Count ([int][Math]::Ceiling($PasswordLength * $Percent))
    }
}

Function ShowProgress {
    [CmdletBinding()]
    param(
        [AllowEmptyCollection()][int]$CurrentItem,
        [Parameter(Mandatory=$true)][int]$TotalItems
    )
    Write-Progress -Activity "Processing.." -status "Password $CurrentItem" `
        -percentComplete ($CurrentItem / $TotalItems*100)
}

Export-ModuleMember -function Get-RandomPassword