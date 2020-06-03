Get the Parent VHD of a differencating XVHD
<#
	.SYNOPSIS
	Finds all the parents of a Hyper-V virtual hard disk (VHD or VHDX).
 
	.DESCRIPTION
	Finds all the parents of a Hyper-V virtual hard disk (VHD or VHDX).
	Files are retrieved from newest (immediate parent of the submitted VHD/X) to oldest (root VHD/X in the chain).
 
	.EXAMPLE
	Get-VHDDifferencingChain -Path 'C:\ClusterStorage\Virtual Hard Disks\vmone-child4.vhdx'
 
	Shows all of the parents of differencing disk vmone-child4.vhdx back to the root.
	#>

{
	param([Parameter(Mandatory=$true)][String]$Path)
	while($Path = (Get-VHDDifferencingParent -Path $Path).ParentPath)
	{
		$Path
	}
}