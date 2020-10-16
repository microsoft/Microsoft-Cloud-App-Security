$storageName = Get-AutomationVariable -Name "storageName"
$containerName = Get-AutomationVariable -Name "containerName"
$dataSource = Get-AutomationVariable -Name "dataSource"

$CASCredential = Get-AutomationPSCredential -Name 'MCAS-API'

$logPathCloud = "https://$storageName.blob.core.windows.net/$containerName/pa-log.log"
$logPath = Join-Path $Env:Temp 'discovery.log'
$newPath = Join-Path $Env:Temp 'new_discovery.log'

#download mcas log from cloud repository
Invoke-WebRequest $logPathCloud -OutFile $logPath

$traffic = Import-Csv $logPath
$newLogs = @()

foreach($transaction in $traffic){

    $bool = Get-Random -Minimum 0 -Maximum 1
    
    #randomize if the transaction should be added to the traffic
    #if($bool -eq 1) {

        #modify the traffic timestamp and format it to match expected format
        $transaction.'Generate Time' = (Get-Date).AddDays(-(Get-Random -Minimum 1 -Maximum 14)).tostring("yyyy/MM/dd HH:mm:ss") | foreach {$_ -replace "-", "/"}
        $transaction.'Bytes Received' = Get-Random -Minimum 5000000 -Maximum 10000000
        $transaction.'Bytes Sent' = Get-Random -Minimum 500000 -Maximum 10000000
        $newLogs += $transaction
    #}
}

$newLogs | Export-Csv -NoTypeInformation -Delimiter ',' -Encoding UTF8 -Path $newPath

# remove " from the log to match expected format
# requires this step, as MCAS API refuses UTF8-BOW, which is produced by PS when using Out-File

$utf8 = New-Object System.Text.UTF8Encoding $false
$temp = Get-Content $newPath -Raw | foreach {$_.Replace('"', '')}
Set-Content -Value $utf8.GetBytes($temp) -Encoding Byte -Path $newPath


#send new log to MCAS tenant for the PaloAlto-Ninja data source
Send-MCASDiscoveryLog -LogFile $newPath -LogType PALO_ALTO -DiscoveryDataSource $dataSource -Credential $CASCredential