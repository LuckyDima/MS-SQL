# Список служб для перевода в состояние Disabled
$servicesToDisable = @(
    "AppReadiness",
    "BalloonService",
    "CDPSvc",
    "CDPUserSvc_50dc38",
    "DPS",
    "FontCache",
    "iphlpsvc",
    "lmhosts",
    "NcbService",
    "PcaSvc",
    "QEMU-GA",
    "SysMain",
    "TabletInputService",
    "TokenBroker",
    "TrkWks",
    "UALSVC",
    "WdNisSvc",
    "WinDefend",
    "wmiApSrv",
    "WpnService",
    "WpnUserService_50dc38"
)

# Перевод каждой службы в состояние Disabled
foreach ($service in $servicesToDisable) {
    Set-Service -Name $service -StartupType Disabled
    Write-Host "Service $service has been set to Disabled."
}
