$serverName = $env:COMPUTERNAME
$os = (Get-WmiObject Win32_OperatingSystem).Caption
$cpu = (Get-WmiObject Win32_Processor).Name
$ram = [math]::round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)

$text = "Server:  $serverName`nOS:      $os`nCPU:    $cpu`nRAM:    $ram GB"

$image = New-Object Drawing.Bitmap 1920,1080
$graphics = [Drawing.Graphics]::FromImage($image)
$graphics.Clear([Drawing.Color]::Black)
$font = New-Object Drawing.Font "Arial", 10
$brush = [Drawing.Brushes]::White
$graphics.DrawString($text, $font, $brush, [Drawing.PointF]::new(50,50))

$outputPath = "C:\Windows\BackgroundPicture.jpg"
$image.Save($outputPath, [Drawing.Imaging.ImageFormat]::Jpeg)

$user = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$regPath = "HKCU:\Control Panel\Desktop"
Set-ItemProperty -Path $regPath -Name Wallpaper -Value $outputPath
RUNDLL32.EXE user32.dll, UpdatePerUserSystemParameters
