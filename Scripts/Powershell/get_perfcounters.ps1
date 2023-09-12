
$Output = @()
$counterset = (Get-Counter -ListSet *).CounterSetName
foreach ($c in $counterset) {
	$Output += $c
	$Output += ""
	$paths = (Get-Counter -ListSet $c).Paths | Sort-Object
	foreach ($p in $paths) {
		$Output += $p
	}
	$instancepaths = (Get-Counter -ListSet $c).PathsWithInstances | Sort-Object
	foreach ($i in $instancepaths) {
		if ($Output -contains $i) {
			break
		}
		else {
			$Output += $i
		}
	}
	$Output += ""
}
$Output | Out-file "D:\PerfCounters.csv"
