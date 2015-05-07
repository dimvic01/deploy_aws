<powershell>
param([switch]$Elevated)

mkdir "c:\download"

$client = new-object System.Net.WebClient
$client.DownloadFile("https://www.python.org/ftp/python/2.7.9/python-2.7.9.amd64.msi", "c:\download\python-2.7.9.amd64.msi")
$client.DownloadFile("http://javadl.sun.com/webapps/download/AutoDL?BundleId=107100", "c:\download\jre-8u45-windows-x64.exe")
#timeout 10 > NUL
start-process -filepath c:\download\jre-8u45-windows-x64.exe -passthru -wait -argumentlist "/s"
start-process -filepath msiexec -passthru -wait -argumentlist "/i c:\download\python-2.7.9.amd64.msi /quiet"
exit 0
</powershell>
