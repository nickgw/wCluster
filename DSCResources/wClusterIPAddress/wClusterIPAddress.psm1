function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $IPAddress,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IPandSubnetMask
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."


    <#
    $returnValue = @{
    IPAddress = [System.String]
    SubnetMask = [System.String]
    IPandSubnetMask = [System.String]
    }

    $returnValue
    #>
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $IPAddress,

        [Parameter()]
        [System.String]
        $SubnetMask,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IPandSubnetMask
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."

    #Include this line if the resource requires a system reboot.
    #$global:DSCMachineStatus = 1


}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $IPAddress,

        [Parameter()]
        [System.String]
        $SubnetMask,

        [Parameter(Mandatory = $true)]
        [System.String]
        $IPandSubnetMask
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."


    <#
    $result = [System.Boolean]

    $result
    #>
}


Export-ModuleMember -Function *-TargetResource

