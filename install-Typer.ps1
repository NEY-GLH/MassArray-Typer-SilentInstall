## install script for Typer 5.0.x with Oracle 19

## script has to do the following (see Typer Release Notes for install guide)
## remove any earlier versions (Typer, TyperReports, OQ Report, Typer Licencing)
## install Licence Manager, Matlab R2015b, R, R packages, Oracle 19 Client, Typer

## Necessary folder structure: .\Rinstall for R setup, .\Rpackages for R packages, .\extracted-typerlm for License Manager and licensekey.txt, .\extracted-typer for Typer MSI, .\Oracle-Instant-Client-2024 for Oracle19, .\matlabruntime for 2015b, Oracle-Client-Config for .ora files

# Set servername (MassArray Analyzer hostname)
$ServerName='AGENADB'

# set License Manager Full Path and remove if not right version
$LMFP = 'C:\Program Files (x86)\Agena\LicenseManager\'
$whatscooking = (Get-Package | where {$_.FullPath -eq $LMFP -and $_.Version -lt '1.2.2'})
if ($whatscooking.Count -gt 0) {Uninstall-Package $whatscooking}

# install Licence Manager
Write-Host "Installing Licence Manager..."
Install-Package '.\extracted-typerlm\License Manager.msi' -Force

# Set R version preference. Set to 'latest' if not specifying a version. Note that 4.1.3 is the latest with the necessary x86 binaries.
$Rpref = '4.1.3'

# Set Oracle root install path
$Oroot = 'c:\Oracle'

# set Matlab silent install options
$harry = @(
    '-mode silent',
    '-agreeToLicense yes'
)

# install Matlab runtime
write-host 'Extracting the Matlab Runtime Installer...'
$MLtmp = md ($env:TEMP+'\'+(New-Guid).Guid)
Expand-Archive .\matlabruntime\MCR_R2015b_win32_installer.zip -DestinationPath $MLtmp.FullName
# Start-Process -FilePath .\matlabruntime\MCR_R2015b_win32_installer.exe -ArgumentList '-inputfile .\matlabruntime\installer_input.txt' -wait -PassThru
write-host 'Installing the Matlab Runtime...'
$jenny = Start-Process -FilePath "$($MLtmp.FullName)\setup.exe" -ArgumentList @($harry) -wait -PassThru
if ($jenny.ExitCode -ne 0) {Write-Warning "MATLAB Runtime did not install successfully`nCheck $env:TEMP\mathworks_$env:USERNAME.txt"} else {write-host 'Matlab Runtime Installed successfully';rd $MLtmp -Recurse -Force}

# set Matlab runtime install dir to check env path
$MLID = 'C:\Program Files (x86)\MATLAB\MATLAB Runtime\v90\runtime\win32'

# set env path
$machineenvpath = [System.Environment]::GetEnvironmentVariable('Path',"Machine")
if ((Select-String -InputObject $machineenvpath -SimpleMatch $MLID).Count -eq 0){
    $nwpth = $MLID+';'+$machineenvpath
    [System.Environment]::SetEnvironmentVariable('Path',$nwpth,"Machine")
}

## R installation
Write-Host "Finding $Rpref version of R installer..."
# get R installer exe
if ($Rpref -eq 'latest') {
    $betty = gci -Path .\Rinstall -Filter *exe|Get-ItemPropertyValue -Name VersionInfo |Where-Object {$_.FileDescription -like "R for Windows*" -and $_.FileDescription -match "Setup"} |sort -desc -Property ProductVersion|select FileName,ProductVersion -First 1
} else {
    $betty = gci -Path .\Rinstall -Filter *exe|Get-ItemPropertyValue -Name VersionInfo |Where-Object {$_.FileDescription -like "R for Windows*" -and $_.FileDescription -match "Setup" -and $_.ProductVersion -match $Rpref} |sort -desc -Property ProductVersion|select FileName,ProductVersion -First 1
}

# get R variables
$ractive = $env:TEMP+'\rsettingsACTIVE-'+(New-Guid).Guid+'.inf'
get-content .\Rinstall\rsettings.inf |foreach-object {$_ -replace 'versionhere',$betty.ProductVersion.Trim()}|Set-Content -Path $ractive
$rdir = (get-content $ractive |Select-String -SimpleMatch "Dir=")
$rfull = $env:SystemDrive+(split-path $rdir -NoQualifier)+'\bin\R.exe'

# do R install
Write-Host "Installing R..."
$RARGS = '/LOADINF='+$ractive+' /VERYSILENT'
$julie = start-process -FilePath $betty.FileName -ArgumentList $RARGS -Wait -WindowStyle Hidden -PassThru
if ($julie.ExitCode -ne 0) {Write-Warning "R did not install successfully"} else {Remove-Item -Path $ractive}

# do R packages install
foreach ($package in (gci .\Rpackages)) {
    write-host "Installing R package; $($package.BaseName)"
    Start-Process -FilePath $rfull -ArgumentList ('CMD INSTALL '+$package.FullName) -Wait -WindowStyle Hidden
    Start-Sleep -s 5
}

# Add R path to Environment PATH
if ((Select-String -InputObject $env:Path -SimpleMatch (Split-Path $rfull -Parent)).Count -eq 0){
    $Rpath = (split-path $rfull -Parent)+';'+$env:Path
    [System.Environment]::SetEnvironmentVariable('Path',$Rpath,"Machine")
}

# Oracle Instant Client installation
Write-Host "Installing Oracle Instant Client..."
if (!(gci $Oroot -ErrorAction Silent)) {md $Oroot}
foreach ($expand in (gci .\Oracle-Instant-Client-2024 -Filter *zip)) {Expand-Archive $expand.FullName -Dest $Oroot -Force}

Write-Host "Registering Oracle ODBC driver..."
$burger = gci -path $Oroot -Filter instantclient* -Directory|sort -Property LastWriteTime -Descending|select -First 1
$florida = start-process (gci $burger.FullName -Filter odbc_install.exe).FullName -Wait -PassThru -WorkingDirectory $burger.FullName
if ($florida.ExitCode -eq 0) {write-host "ODBC install success"}

$cheese = $burger.FullName+'\network\admin'
md $cheese

# Confirm an Oracle ODBC client registered
if (!(Get-OdbcDriver -Name Oracle*)) {Write-Warning "No Oracle ODBC driver registered"}

# Oracle environment
$Oenv = @{
    TNS_ADMIN = $cheese
    NLS_LANG = 'AMERICAN_AMERICA.AL32UTF8'
}
foreach ($vrb in $Oenv.Keys) {
    [System.Environment]::SetEnvironmentVariable($vrb,$Oenv[$vrb],"Machine")
}

# Oracle Local Naming Parameters for AgenaDB
cp .\Oracle-Client-Config\*.ora -Destination $cheese -Force

# Get ODBC connection info - AES key to encrypt password generated as described here; https://www.pdq.com/blog/secure-password-with-powershell-encrypting-credentials-part-2/
$KeyFile = '.\Oracle-Client-Config\AES-agenadb.key'
$PasswordFile = '.\Oracle-Client-Config\odbcpass.dat'
$Key = Get-Content $KeyFile
$Password = [pscredential]::new(0,(Get-Content $PasswordFile | ConvertTo-SecureString -Key $Key)).GetNetworkCredential().Password

# Oracle make ODBC DSN
Write-Host "Adding ODBC DSN connection..."
#$dsnpropvalues = (Import-Clixml -Path .\Oracle-Client-Config\dsnproperties.xml) -replace 'Password=',"Password=$Password"
$myodbcdriver = get-odbcdriver -name Oracle* |Select-Object -Property Name,Attribute |where {$_.Attribute.Driver -like ($($burger.Fullname)+'*')}
#Add-OdbcDsn -Name "agenadb" -DriverName $myodbcdriver.Name -Platform '32-bit' -DsnType System -SetPropertyValue @(foreach ($m in $dsnpropvalues){"$m",})
Add-OdbcDsn -Name "agenadb" -DriverName $myodbcdriver.Name -Platform '32-bit' -DsnType System -SetPropertyValue ("ServerName=$ServerName","UserID=charles","DSN=agenadb","Password=$Password")

# Install Typer
Write-Host "Installing main Typer package..."
Install-Package '.\extracted-typer\MassARRAY Typer.msi' -Force

# add Licence code to registry
$lickey = get-content (gci -Path .\extracted-typerlm -Filter *key.txt |Select -First 1).FullName
$regpath = 'HKLM:\SOFTWARE\WOW6432Node\MassARRAY\Typer-4'
Set-ItemProperty -Path $regpath -Name 'CompanyName' -Value (($lickey |select-string -Pattern company) -split " "|Select-Object -Last 1)
Set-ItemProperty -Path $regpath -Name 'RegisterKey' -Value (($lickey |select-string -Pattern license) -split " "|Select-Object -Last 1)
Set-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Typer-4' -Name 'CustomerId' -Value (($lickey |select-string -Pattern CustomerId) -split " "|Select-Object -Last 1)

# Add version to registry for Licence Manager
$finale = Get-Package -Name 'MassARRAY Typer'
Set-ItemProperty -Path $regpath -Name 'Version' -Value $($finale.Version).Trim()
Set-ItemProperty -Path $regpath -Name 'TVersion' -Value $($finale.Version).Trim()

# Customise Typer install
$typrsystm = "$env:ProgramData\Agena\Typer\System"
if (!(Test-Path $typrsystm)) {md $typrsystm}
cp '.\extracted-typer\ColumnInfo.xml' -Destination $typrsystm -Force

# Clear password
clv Password,Key,lickey
Write-Host "Complete"