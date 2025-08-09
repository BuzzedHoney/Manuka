try {
    Write-Host "Blocking Spying Domains"
    Start-Sleep -Seconds 3
    $domains = @(
    # Bing
    "bing.com",
    "business.bing.com",
    "c.bing.com",
    "th.bing.com",
    "tse1.mm.bing.net",
    # MSN
    "msn.com",
    "www.msn.com",
    "arc.msn.com",
    "api.msn.com",
    "assets.msn.com",
    "browser.events.data.msn.com",
    "c.msn.com",
    "fd.api.iris.microsoft.com",
    "g.msn.com",
    "ntp.msn.com",
    "srtb.msn.com",
    "staticview.msn.com",
    # Microsoft Edge
    "msedge.net",
    "a-ring-fallback.msedge.net",
    "c-ring.msedge.net",
    "dual-s-ring.msedge.net",
    "evoke-windowsservices-tas.msedge.net",
    "fp.msedge.net",
    "fp-vs.azureedge.net",
    "I-ring.msedge.net",
    "ln-ring.msedge.net",
    "prod-azurecdn-akamai-iris.azureedge.net",
    "s-ring.msedge.net",
    "t-ring.msedge.net",
    # Other
    "oca.telemetry.microsoft.com",
    "oca.microsoft.com",
    "watson.telemetry.microsoft.com",
    "umwatsonc.events.data.microsoft.com",
    "umwatson.events.data.microsoft.com",
    "watsonc.events.data.microsoft.com",
    "eu-watsonc.events.data.microsoft.com",
    "kmwatsonc.events.data.microsoft.com",
    "telecommand.telemetry.microsoft.com",
    "www.telecommandsvc.microsoft.com",
    "functional.events.data.microsoft.com",
    "self.events.data.microsoft.com",
    "v10.events.data.microsoft.com",
    "v10c.events.data.microsoft.com",
    "us-v10c.events.data.microsoft.com",
    "eu-v10c.events.data.microsoft.com",
    "v10.vortex-win.data.microsoft.com",
    "v20.events.data.microsoft.com",
    "vortex-win.data.microsoft.com",
    "inference.location.live.net",
    "location-inference-westus.cloudapp.net",
    "settings-win.data.microsoft.com",
    "settings.data.microsoft.com",
    "mucp.api.account.microsoft.com",
    "query.prod.cms.rt.microsoft.com",
    "ris.api.iris.microsoft.com",
    "cdn.onenote.net",
    "config.edge.skype.com",
    "tile-service.weather.microsoft.com",
    "maps.windows.com",
    "dev.virtualearth.net",
    "ecn.dev.virtualearth.net",
    "ecn-us.dev.virtualearth.net",
    "ceuswatcab01.blob.core.windows.net",
    "ceuswatcab02.blob.core.windows.net",
    "eaus2watcab01.blob.core.windows.net",
    "eaus2watcab02.blob.core.windows.net",
    "weus2watcab01.blob.core.windows.net",
    "weus2watcab02.blob.core.windows.net",
    "weathermapdata.blob.core.windows.net",
    "edgeassetservice.azureedge.net",
    "fp-afd-nocache-ccp.azureedge.net",
    "widgetcdn.azureedge.net",
    "widgetservice.azurefd.net",
    "cs11.wpc.v0cdn.net",
    "creativecdn.com"
    )
    foreach ($domain in $domains) {
        $ruleExists = Get-NetFirewallRule -DisplayName $domain -ErrorAction SilentlyContinue
        if (-not $ruleExists) {
            $resolvedIPs = Resolve-DnsName $domain -ErrorAction SilentlyContinue | Where-Object { $_.Type -eq "A" } | Select-Object -ExpandProperty IPAddress

            if ($resolvedIPs) {
                New-NetFirewallRule -DisplayName $domain `
                                    -Direction Outbound `
                                    -Action Block `
                                    -RemoteAddress $resolvedIPs `
                                    -Profile Domain,Private,Public `
                                    -Enabled True `
                                    -Description "Blocked telemetry/tracking domain" | Out-Null
                Write-Host "Blocked $domain"
            }
            else {
                Write-Host "Could not resolve $domain"
            }
        }
        else {
            Write-Host "Rule already exists for $domain"
        }
    }
    Write-Host "Privacy Enhanced"
}
catch {
    Write-Host "An error occurred: $_"
}
