# Install Chocolatey 
Start-Transcript -Path C:\psLogs.txt -Append
Set-ExecutionPolicy Unrestricted -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
# Installing Windows Terminal
Write-Host "Installing Windows Terminal"
choco install microsoft-windows-terminal -y

# Install dotnet 
Write-Host "Installing Dotnet 6"
choco install dotnet-6.0-sdk -y
Write-Host "Installing Dotnet 7 runtime"
choco install dotnet-runtime -y

# Install Software
Write-Host "Installing Azure Data Studio"
choco install azure-data-studio -y
Write-Host "Installing Azure CLI"
choco install azure-cli -y
Write-Host "Installing DotNet Core"
choco install dotnetcore -y

# Function to create folders
function CreateFolder {
    param (
        [Parameter()] [String] $FolderName
    )

    if (Test-Path $FolderName) {
   
        Write-Host "Folder Exists"
    }
    else {
      
        #PowerShell Create directory if not exists
        New-Item $FolderName -ItemType Directory
        Write-Host "Folder Created successfully"
    }
    
}

Write-Host "Creating folders"
#Destination Path
$OutputTargetDirectory = "C:\temp\output"
$ProjectsTargetDirectory = "C:\temp\projects"
$SHIRTargetDirectory = "C:\temp\SHIR"

#Create Folders
CreateFolder $OutputTargetDirectory
CreateFolder $ProjectsTargetDirectory
CreateFolder $SHIRTargetDirectory

Write-Host "Setting variable"
$env:Path += "C:\Program Files\dotnet;"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
refreshenv
$env:Path += "C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin;"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
refreshenv

# Installing SqlPackage
Write-Host "Installing SqlPackage"
dotnet tool install -g microsoft.sqlpackage

$env:Path += "C:\Windows\System32\config\systemprofile\.dotnet\tools;"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
refreshenv

# Installig Azure SQL migration extension for Azure Data Studio
Write-Host "Installig Azure SQL migration extension"
Start-Process -filePath "C:\Program Files\Azure Data Studio\bin\azuredatastudio" -ArgumentList "--install-extension Microsoft.sql-migration","--force" -Wait
Start-Process -filePath "C:\Program Files\Azure Data Studio\bin\azuredatastudio" -ArgumentList @("--install-extension microsoft.sql-migration","--force")
# Downaloading and installig Integration Runtime
Write-Host "Downloading Integration Runtime"
Invoke-WebRequest -Uri https://download.microsoft.com/download/E/4/7/E4771905-1079-445B-8BF9-8A1A075D8A10/IntegrationRuntime_5.23.8324.1.msi -OutFile C:\temp\SHIR\IntegrationRuntime_5.23.8324.1.msi; 
Write-Host "Installing Integration Runtime"
Start-Process msiexec.exe -Wait -ArgumentList '/I C:\temp\SHIR\IntegrationRuntime_5.23.8324.1.msi /quiet';

# add extension
Write-Host "Adding AZ extension"
az extension add --name datamigration --verbose

# add extension
Write-Host "Setting Execution Policy"
#Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy RemoteSigned

Stop-Transcript
