# MassArray-Typer-SilentInstall
Deployment script for the Agena Bioscience MassArray Typer software suite

The dependencies need to be added to subfolders from the script.

\extracted-typerlm
- 'License Manager.msi' - extracted from the installer package
- *key.txt - single text file ending in 'key.txt' containing the licence key. Fields are spaced between a keyword and the value. e.g. 'Company Name: MYCOMPANY'.
    Search values are 'company', 'license' and 'CustomerID'. The last 'object' (space-separated) item on the line will be the value (i.e. the Company Name, License, etc).
    Above values are provided by Agena Bio, but 'CustomerID' must be obtained from a manual installation which has been licenced using the License Manager manually. The value will be contained in 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Typer-4\CustomerID'.

\extracted-typer
- 'MassARRAY Typer.msi' - extracted from the installer package
- 'ColumnInfo.xml' - optional customisation of the GUI for end-users. Copies to the ProgramData folder at the end of the install. Can be commentted out.

\matlabruntime
- 'MCR_R2015b_win32_installer.zip' - unchanged distributable version of the 32-bit Matlab 9.0b Runtime install package.

\Oracle-Client-Config
- 'AES-agenadb.key' - key for encrypting/decrypting the password to connect to the Oracle DB. Must be generated manually. *RECOMMEND RELOCATING THIS FILE SOMEWHERE ONLY CONFIGURATION MANAGER CAN READ*
- 'odbcpass.dat' - encrypted password for the Oracle DB. Must be generated manually. See https://www.pdq.com/blog/secure-password-with-powershell-encrypting-credentials-part-2/
- sqlnet.ora - contains the following...
    SQLNET.AUTHENTICATION_SERVICES= (NONE)
- tnsnames.ora - contains the following (remember to change the hostname)...
    AGENADB =
  (DESCRIPTION =
    (ADDRESS_LIST =
      (ADDRESS = (PROTOCOL = TCP)(HOST = *YOURHOSTNAMEHERE*)(PORT = 1521))
    )
    (CONNECT_DATA =
      (SERVICE_NAME = BMS)
    )
  )

\Oracle-Instant-Client-2024
- 'instantclient-basic-nt-19.22.0.0.0dbru.zip' - unchanged distributable for the Oracle Instant Client 19
- 'instantclient-odbc-nt-19.22.0.0.0dbru.zip' - unchanged distributable for the Oracle Instant Client ODBC module

\Rinstall
- 'R-4.1.3-win.exe' - unchanged distributable for the R installation. Any version can be downloaded here. Script looks at the file description on the .exe and matches to preferred version number or 'latest'. See variable $Rpref near top of script.
- 'rsettings.inf' - contains the following (required to install only 32-bit components)...
    [Setup]
    Lang=en
    Dir=C:\Program Files\R\R-versionhere
    Group=R
    NoIcons=1
    SetupType=user
    Components=main,i386,translations
    Tasks=recordversion,associate
    [R]
    MDISDI=MDI
    HelpStyle=HTML

\Rpackages - contains unchanged .zip versions of the R packages from the CRAN repository. Latest versions supporting 32-bit 4.1.3 R at the time of testing...
- 'doBy_4.6.20.zip'
- 'gap_1.5-3.zip'
- 'RODBC_1.3-23.zip'
- 'RSQLite_2.3.6.zip'
- 'shiny_1.8.1.zip'
- 'shinyjs_2.1.0.zip'
