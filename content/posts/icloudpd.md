+++
title = "Downloading and converting iCloud photos"
date = 2026-01-04T14:28:00+01:00

[taxonomies]
tags = ["icloud", "icloudpd"]
+++

This tool lets you download all of your photos, or just the ones from a specific album, straight to your own machine. It's noticeably faster than going through the iCloud web interface itself, and on repeated runs it only grabs the new files.

After that, the `*.heic` images can be converted to JPEG with ImageMagick. But for that to work, all the images need to be in one directory.

## Start PowerShell as Admin

```powershell
# Allow script execution
Set-ExecutionPolicy AllSigned
# Install Chocolatey https://chocolatey.org/install
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
# Close PowerShell and reopen it as Admin
# Install Python via Chocolatey https://www.python.org/
choco install python
# Install ImageMagick and exiftool via Chocolatey https://imagemagick.org/index.php
choco install ImageMagick exiftool
# Close PowerShell and reopen it as admin
# Install the icloudpd Python client for iCloud Photos https://github.com/icloud-photos-downloader/icloud_photos_downloader
pip install icloudpd
pip install pyicloud
# Close PowerShell and
```

## Start a new cmd (not PowerShell) as a normal user

```powershell
# Log in for the first time and store the password in the system
$ icloud --username username@example.com
ICloud Password for username@example.com:
Save password in keyring? (y/N)
# Answer with y
# Confirm on your iPhone and enter the code
```

## Create the directory structure

```
H:\iCloud
H:\iCloud\download
H:\iCloud\fotos
H:\iCloud\tools
```

Download the exiftool Windows executable (<https://exiftool.org/>) and save it as `exiftool.exe` in `H:\iCloud\tools`.

## Batch files

Create 4 batch files in `H:\iCloud`:

```powershell,name=01-download-all.bat
@echo off
icloudpd.exe -u username@example.com --folder-structure {:%%Y/%%Y-%%m} --set-exif-datetime --skip-live-photos --log-level error --directory "H:\iCloud\download"
pause
```

The value for `--recent` should be adjusted so that all photos from the past year get downloaded. When in doubt, just use a way-too-large number. This means already-downloaded photos get downloaded again and it takes longer, but you can be sure you've got everything.

```powershell,name=02-download-recent.bat
@echo off
icloudpd.exe -u username@example.com --folder-structure {:%%Y/%%Y-%%m} --set-exif-datetime --skip-live-photos --log-level error --recent 500 --directory "H:\iCloud\download"
pause
```

```powershell,name=03-convert.bat
@echo off
echo %DATE% %TIME% mogrify start >> H:\iCloud\error.log
echo Converting *.HEIC -> *.JPG
FOR /R H:\iCloud\download %%G IN (*.HEIC) DO (
   if not exist "%%~pG\%%~nG.jpg" magick mogrify -format jpg -define preserve-timestamp=true "%%G" 2>> H:\iCloud\error.log
   del "%%G"
)
echo %DATE% %TIME% mogrify end >> H:\iCloud\error.log
echo Done.
pause
```

```powershell,name=04-rename.bat
@echo off
echo %DATE% %TIME% exiftool start >> H:\iCloud\error.log
echo Renaming files
H:
cd H:\iCloud
.\tools\exiftool -d .\fotos\%%Y\%%Y-%%m\%%Y-%%m-%%d_%%H-%%M-%%S_%%%%lf.%%%%le "-filename<filemodifydate" "-filename<createdate" "-filename<datetimeoriginal" -r .\download 2>> H:\iCloud\error.log
echo %DATE% %TIME% exiftool done >> H:\iCloud\error.log
pause
```
