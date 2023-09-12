
$sharepath = "\\auth.hpicorp.net\HPI\205254_hpit-w-grpshares-inc-prd_HPITSoftwareDownloads\Microsoft\Servers\temp2"
$servers = Import-Csv "$sharepath\Servers.csv"
$array = @()

foreach($server in $servers){
    $computername=$server.computername

    #Define the variable to hold the location of Currently Installed Programs
    $UninstallKey=”SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall” 

    #Create an instance of the Registry Object and open the HKLM base key
    $reg=[microsoft.win32.registrykey]::OpenRemoteBaseKey(‘LocalMachine’,$computername) 

    #Drill down into the Uninstall key using the OpenSubKey Method
    $regkey=$reg.OpenSubKey($UninstallKey) 

    #Retrieve an array of string that contain all the subkey names
    $subkeys=$regkey.GetSubKeyNames() 

    #Open each Subkey and use GetValue Method to return the required values for each
    foreach($key in $subkeys){
        $thisKey=$UninstallKey+”\\”+$key 
        $thisSubKey=$reg.OpenSubKey($thisKey) 
        $obj = New-Object PSObject
        $obj | Add-Member -MemberType NoteProperty -Name “ComputerName” -Value $computername
        $obj | Add-Member -MemberType NoteProperty -Name “DisplayName” -Value $($thisSubKey.GetValue(“DisplayName”))
        $obj | Add-Member -MemberType NoteProperty -Name “DisplayVersion” -Value $($thisSubKey.GetValue(“DisplayVersion”))
        $obj | Add-Member -MemberType NoteProperty -Name “InstallLocation” -Value $($thisSubKey.GetValue(“InstallLocation”))
        $obj | Add-Member -MemberType NoteProperty -Name “Publisher” -Value $($thisSubKey.GetValue(“Publisher”))
        $array += $obj
    } 

}
$array | Where-Object { $_.DisplayName } | Select-Object ComputerName, DisplayName, DisplayVersion, Publisher | Export-Csv -Path $sharepath\InstalledApps.csv -NoTypeInformation
