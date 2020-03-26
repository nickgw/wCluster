<#
.Synopsis
   Given an IP Address and a Subnet Mask, returns the IP Addresses subnet.
.DESCRIPTION
   Returns an IPAddress object of the subnet mask of the given IPAddress and Subnet.
.EXAMPLE
   Get-Subnet -IPAddress 10.235.32.129 -SubnetMask 255.255.255.128
.EXAMPLE
   Get-Subnet -IPandSubnet 10.235.32.129/255.255.255.128
#>
function Get-Subnet
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([IpAddress])]
    Param
    (
        # IPAddress to add to Cluster
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName = "Default",
                   Position=0)]
        [IPAddress]$IPAddress,

        # SubnetMask of IPAddress
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName = "Default",
                   Position=1)]
        [IPAddress]$SubnetMask,

        #CombinedIPAddressandSubnet
        [Parameter(Mandatory=$true,
                   ValueFromPipelineBYPropertyName=$true,
                   ParameterSetName="Combined",
                   Position=0)]
        [String]$IPandSubnet
    )

    Begin
    {
        $f = "$($PSCmdlet.CommandRunTime): "
        switch ( $PsCmdlet.ParameterSetName ) {
          "Combined" {
              Write-Verbose "$f Combined IP and SubnetMask were passed as $IPandSubnet"

              [IPAddress]$IPAddress  = $IPandSubnet.Split('/')[0]
              [IPAddress]$SubnetMask = $IPandSubnet.Split('/')[1]
              Write-Verbose "$f IP and SubnetMask split as $IPAddress and $SubnetMask"
          }
        }
        $ErrorActionPreference = 'Stop'
    }
    Process
    {
        $subnet = [IPAddress]($Ipaddress.Address -band $SubnetMask.Address)
    }
    End
    {
        return $Subnet
    }
}

<#
.Synopsis
   Adds an IPAddress as a Dependency to a Windows Cluster
.DESCRIPTION
   Adds an IP Address resource to a Windows Cluster's Dependecy Expression
.EXAMPLE
   # Using the default ParameterSet of both IP Address and Subnet
   Add-ClusterIPAddressDependency -IPAddress 10.235.32.137 -Subnet 255.255.255.128 -Verbose
.EXAMPLE
    # Using the Combined ParameterSet
    Add-ClusterIPAddressDependency -IPandSubnet 10.235.32.137/255.255.255.128 -Verbose
.AUTHOR
    Nick Germany
#>
function Add-ClusterIPAddressDependency
{
    [CmdletBinding()]
    [Alias()]

    Param
    (
        # IPAddress to add to Cluster
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName = "Default",
                   Position=0)]
        [IPAddress]$IPAddress,

        # SubnetMask of IPAddress
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName = "Default",
                   Position=1)]
        [IPAddress]$SubnetMask,

        #CombinedIPAddressandSubnet
        [Parameter(Mandatory=$true,
                   ValueFromPipelineBYPropertyName=$true,
                   ParameterSetName="Combined",
                   Position=0)]
        [String]$IPandSubnet
    )

    Begin
    {
        $f = "$($PSCmdlet.CommandRunTime): "
        switch ( $PsCmdlet.ParameterSetName ) {
          "Combined" {
              Write-Verbose "$f Combined IP and SubnetMask were passed as $IPandSubnet"

              [IPAddress]$IPAddress  = $IPandSubnet.Split('/')[0]
              [IPAddress]$SubnetMask = $IPandSubnet.Split('/')[1]
              Write-Verbose "$f IP and SubnetMask split as $IPAddress and $SubnetMask"
          }
        }
    }
    Process
    {
        #* Get Windows Cluster resource
        Write-Verbose "$f Getting Windows Cluster resource"
        $cluster = Get-ClusterResource | Where-Object { $_.name -eq 'Cluster Name'}

        #* Create new IPAddress resource and add the IPAddress parameters to it
        Write-Verbose "$f Creating new IP Address cluster resource for IP $IPAddress and Subnet Mask $SubnetMask"
        $params = @{
          Name         = "IP Address $IPAddress"
          ResourceType = "IP Address"
          Group        = $($cluster.OwnerGroup.Name)
        }
        $ipResource = Add-ClusterResource @params
        $parameter1 = New-Object Microsoft.FailoverClusters.PowerShell.ClusterParameter $ipResource,Address,$($ipAddress.IPAddressToString)
        $parameter2 = New-Object Microsoft.FailoverClusters.PowerShell.ClusterParameter $ipResource,SubnetMask,$($subnetMask.IPAddressToString)
        $parameterList = $parameter1,$parameter2

        #* Add the IP Address resource to the cluster
        Try {
            Write-Verbose "$f Attempting to add the IP Address resource to the cluster"
            $ErrorActionPreference = 'Stop'
            $parameterList | Set-ClusterParameter
        } Catch {
          #TODO Add error handling here for failure. Most likely reasons are
          #* IP Address already exists (does this check actuall IP Address or just IP Address Name)
          #* IP Address network has yet to be added to the Cluster
          Write-Error "$f failed to add the IP Address resource to the cluster"
          break
        }

        Write-Verbose "$f Getting all IP Address resources from the Windows Cluster"
        $ipResources = Get-ClusterResource | Where-Object {
            ( $_.OwnerGroup -eq $cluster.OwnerGroup ) -and
            ( $_.ResourceType -eq 'IP Address' )
          }

        Write-Verbose "$f Building IP Resource DependencyExpression"
        $dependencyExpression = ''
        $i = 0
        while ( $i -lt ( $ipResources.count ) ) {
          if ( $i -eq ( $ipResources.count -  1) ) {
              $dependencyExpression += "[$($ipResources[$i].name)]"
          } else {
              $dependencyExpression += "[$($ipResources[$i].name)] or "
          }
          $i++
        }

        #Set cluster resources
        Try {
          $params = @{
            Resource    = $($cluster.Name)
            Dependency  = $dependencyExpression
            ErrorAction = 'Stop'
          }
          Write-Verbose "$f Setting DependencyExpression  as $dependencyExpression"
          Set-ClusterResourceDependency @params
        } Catch {
          #TODO error handling for when adding the depenencies list fails
          Write-Error "$f Failed to set DependencyExpression"
          break
        }

    }
    End
    {
      return $True
    }
}

<#
.Synopsis
   Tests whether a given IPAddress is part of the Cluster's DependencyExpression
.DESCRIPTION
   Long description
.EXAMPLE
   Example using complete IPAddress and Subnetmask default ParameterSet
   Test-ClusterIPAddressDependency -IPAddress 10.235.0.141 -SubnetMask 255.255.255.128 -verbose
.EXAMPLE
   Example using IPAddress from default ParameterSet
   Test-ClusterIPAddressDependency -IPAddress 10.235.0.141 -verbose
.EXAMPLE
   Example using Combined ParameterSet
   Test-ClusterIPAddressDependency -IPandSubnet 10.235.0.141/255.255.255.128 -verbose
#>
function Test-ClusterIPAddressDependency
{
    [CmdletBinding()]
    [Alias()]
    Param
    (
        # IPAddress to add to Cluster
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName = "Default",
                   Position=0)]
        [IPAddress]$IPAddress,

        # SubnetMask of IPAddress
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName = "Default",
                   Position=1)]
        [IPAddress]$SubnetMask,

        #CombinedIPAddressandSubnet
        [Parameter(Mandatory=$true,
                   ValueFromPipelineBYPropertyName=$true,
                   ParameterSetName="Combined",
                   Position=0)]
        [String]$IPandSubnet
    )

    Begin
    {
        $f = "$($PSCmdlet.CommandRunTime): "
        switch ( $PsCmdlet.ParameterSetName ) {
          "Combined" {
              Write-Verbose "$f Combined IP and SubnetMask were passed as $IPandSubnet"

              [IPAddress]$IPAddress  = $IPandSubnet.Split('/')[0]
              [IPAddress]$SubnetMask = $IPandSubnet.Split('/')[1]
              Write-Verbose "$f IP and SubnetMask split as $IPAddress and $SubnetMask"
          }
        }
        $ErrorActionPreference = 'Stop'
    }
    Process
    {
      Try {
        Write-Verbose "$f Getting Cluster DependencyExpression"
        $cluster = Get-ClusterResource | Where-Object {$_.name -eq 'Cluster Name'}
        $dependencyExpression = (Get-ClusterResourceDependency -Resource $cluster.Name).DependencyExpression
      } Catch {
        Write-Error "$f Failed to get cluster dependencies. Is $($env:ComputerName) joined to a cluster?"
      }

      Write-Verbose "$f Testing if $IPAddress is in DependencyExpression $dependencyExpression"
      If ( $dependencyExpression -match $IPAddress ) {
        Write-Verbose "$f $IPAddress is in DependencyExpression $dependencyExpression"
        $returnObj = $True
      } else {
        Write-Verbose "$f $IPAddress is not in DependencyExpression $dependencyExpression"
        $returnObj = $False
      }
    }
    End
    {
      return $returnObj
    }
}

<#
.Synopsis
   Checks whether the ClusterNetwork for a given IPAddress has been added to a Cluster
.DESCRIPTION
   Given an IPAddress and SubnetMask this cmdlet will check if the correct ClusterNetwork has
   been added to the cluster.
.EXAMPLE
   Test-ClusterNetwork -IPAddress 10.245.10.32 -SubnetMask 255.255.255.0
.EXAMPLE
   Test-ClusterNetwork -IPandSubnet 10.245.10.32/255.255.255.0
#>
function Test-ClusterNetwork
{
    [CmdletBinding()]
    [Alias()]
    Param
    (
        # IPAddress to add to Cluster
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName = "Default",
                   Position=0)]
        [IPAddress]$IPAddress,

        # SubnetMask of IPAddress
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName = "Default",
                   Position=1)]
        [IPAddress]$SubnetMask,

        #CombinedIPAddressandSubnet
        [Parameter(Mandatory=$true,
                   ValueFromPipelineBYPropertyName=$true,
                   ParameterSetName="Combined",
                   Position=0)]
        [String]$IPandSubnet
    )

    Begin
    {
        $f = "$($PSCmdlet.CommandRunTime): "
        switch ( $PsCmdlet.ParameterSetName ) {
          "Combined" {
              Write-Verbose "$f Combined IP and SubnetMask were passed as $IPandSubnet"

              [IPAddress]$IPAddress  = $IPandSubnet.Split('/')[0]
              [IPAddress]$SubnetMask = $IPandSubnet.Split('/')[1]
              Write-Verbose "$f IP and SubnetMask split as $IPAddress and $SubnetMask"
          }
        }
        $ErrorActionPreference = 'Stop'
    }
    Process
    {
        Write-Verbose "$f Getting all networks added to this cluster."
        $clusterNetworks = New-Object "System.Collections.Generic.List[PSCustomObject]"
        Foreach ( $network in Get-ClusterNetwork ) {
            $clusterNetworks.Add([PSCustomObject]@{
                Address     = $network.Address
                AddressMask = $network.AddressMask
            })

            Write-Verbose "$f Found cluster network $($network.Address)/$($Network.AddressMask)"
        }

        Write-Verbose "$f Getting the subnet of the given IPAddress $IPAddress with subnet mask $SubnetMask"
        $subnet = $(Get-Subnet -IPAddress $IPAddress -SubnetMask $SubnetMask -Verbose)
        Write-Verbose "$f IPAddress $IPAddress with Subnet Mask $SubnetMask is in subnet $Subnet"

        $returnObj = $False

        foreach ( $network in $clusterNetworks ) {
          if (
               ( $network.Address -eq $subnet.IPAddressToString ) -and
               ( $network.AddressMask -eq $SubnetMask.IPAddressToString )
            ){
            Write-Verbose "$f Subnet $($network.address) for IPAddress $IPAddress network $subnet is added to the cluster"
            $returnObj = $True
          }
        }
    }
    End
    {
        return $returnObj
    }
}

Function Get-TargetResource
{
    Param
    (
        # IPAddress to add to Cluster
        [Parameter(Mandatory=$true)]
        [System.String]
        $IPAddress
    )
    Begin
    {
        $f = "$($PSCmdlet.CommandRunTime): "
        $IPAddress,$SubnetMask = $IPAddress.Split('/')

        if ( $SubnetMask.length -lt 3 ) {
            Write-Verbose "$f IPAddress passed in CIDR notation. Translating $SubnetMask from CIDR to SubnetMask"
            # This CIDR => Subnetmask code was shamelessly stolen from https://www.reddit.com/r/PowerShell/comments/81x324/shortest_script_challenge_cidr_to_subnet_mask/dv6jkj5
            $SubnetMask = (0..3|%{(,0*($_*8+1)+('Ààðøüþÿ'|% t*y|%{+$_})+,255*(24-$_*8))[$SubnetMask]})-join'.'
        }
        $ErrorActionPreference = 'Stop'
    }
    Process
    {
        $returnObj = [PSCustomObject]@{
            IPAddress   = [System.Collections.Generic.List[IPAddress]]::New()
            SubnetMask  = [System.Collections.Generic.List[IPAddress]]::New()
            IPandSubnetMask = [System.Collections.Generic.List[String]]::New()
        }
        Write-Verbose "$f Getting all IPAddresses added to this cluster."

        $clusterNetworks = New-Object "System.Collections.Generic.List[PSCustomObject]"
        Foreach ( $network in Get-ClusterNetwork ) {
            $clusterNetworks.Add([PSCustomObject]@{
                Address     = $network.Address
                AddressMask = $network.AddressMask
            })
        }

        $rawIPAddresses = (Get-ClusterResourceDependency -Resource 'Cluster Name').DependencyExpression.replace('[IP Address ','').replace(']',$null).replace(' ', $null).split('or')

        Foreach ( $ip in $rawIPAddresses ) {
            Try {
                # Simple test for whether the list item from $rawIPAddresses is an IPAddress or not
                $null = [IPAddress]$ip

                $returnObj.IPAddress.Add($ip)

                foreach ( $net in $clusterNetworks ) {
                    $ipSplit = $($ip.split('.'))
                    $ipOct = "$($ipSplit[0]).$($ipSplit[1]).$($ipSplit[2])"

                    if ( $net.address -match $ipOct ) {
                        Write-Verbose "$f Found cluster network $($net.Address)/$($net.AddressMask)"
                        $returnObj.SubnetMask.Add([IPAddress]$($net.AddressMask))
                        $returnObj.IPandSubnetMask.Add("$ip/$($net.AddressMask)")
                    }
                }

            } Catch {
                Write-Verbose "$f Item from DependencyExpression was not an IPAddress"
            }
        }
    }
    End
    {
      return $returnObj
    }
}

Function Set-TargetResource
{
    Param
    (
        # IPAddress to add to Cluster
        [Parameter(Mandatory=$true)]
        [System.String]
        $IPAddress
    )
    Begin
    {
        $f = "$($PSCmdlet.CommandRunTime): "
        $IPAddress,$SubnetMask = $IPAddress.Split('/')

        if ( $SubnetMask.length -lt 3 ) {
            Write-Verbose "$f IPAddress passed in CIDR notation. Translating $SubnetMask from CIDR to SubnetMask"
            # This CIDR => Subnetmask code was shamelessly stolen from https://www.reddit.com/r/PowerShell/comments/81x324/shortest_script_challenge_cidr_to_subnet_mask/dv6jkj5
            $SubnetMask = (0..3|%{(,0*($_*8+1)+('Ààðøüþÿ'|% t*y|%{+$_})+,255*(24-$_*8))[$SubnetMask]})-join'.'
        }
        $ErrorActionPreference = 'Stop'
    }
  Process
  {
    # We've gotten here because the IPAddress given is not in the DependencyExpression for the cluster
    # We need to Check if the network is added to the cluster. If not, we fail. If it is, we can append the IPAddress

    # How can this be made more idempotent?
    $params = @{
      IPAddress  = $IPAddress
      SubnetMask = $SubnetMask
    }
    $networkAdded = Test-ClusterNetwork @params

    if ( -not $networkAdded ) {
      Write-Error "$f ClusterNetwork for IPAddress $IPAddress and subnet mask $SubnetMask is not part of this Cluster"
      break
    } else {
      Write-Verbose "$f The subnet for IPAddress $IPAddress and subnet mask $SubnetMask is part of this Cluster"

      Try {
        $params = @{
          IPAddress  = $IPAddress
          SubnetMask = $SubnetMask
        }
        Write-Verbose "$f Attempting to add $IPAddress/$SubnetMask as a Cluster Dependency"
        Add-ClusterIPAddressDependency @params
      }
      Catch {
        Write-Error $error[0]
        break
      }
    }
  }
  End
  {

  }
}

Function Test-TargetResource
{
    Param
    (
        # IPAddress to add to Cluster
        [Parameter(Mandatory=$true)]
        [System.String]
        $IPAddress
    )
    Begin
    {
        $f = "$($PSCmdlet.CommandRunTime): "
        $IPAddress,$SubnetMask = $IPAddress.Split('/')

        if ( $SubnetMask.length -lt 3 ) {
            Write-Verbose "$f IPAddress passed in CIDR notation. Translating $SubnetMask from CIDR to SubnetMask"
            # This CIDR => Subnetmask code was shamelessly stolen from https://www.reddit.com/r/PowerShell/comments/81x324/shortest_script_challenge_cidr_to_subnet_mask/dv6jkj5
            $SubnetMask = (0..3|%{(,0*($_*8+1)+('Ààðøüþÿ'|% t*y|%{+$_})+,255*(24-$_*8))[$SubnetMask]})-join'.'
        }
        $ErrorActionPreference = 'Stop'
    }
  Process
  {
    # If IPAddress is not in ClusterResource DependencyExpression #fail
    # If IPAddress' Subnet is not in ClusterNetworks #fail
    Write-Verbose "$f Testing if IPAddress $ipaddress is part of the Cluster DependencyExpression"
    $params = @{
      IPAddress  = $IPAddress
      SubnetMask = $SubnetMask
    }
    $returnObj = Test-ClusterIPAddressDependency @params

  }
  End
  {
      return $returnObj
  }
}