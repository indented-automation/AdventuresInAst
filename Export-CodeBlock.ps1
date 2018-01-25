[CmdletBinding()]
param (
    [String]$Path = 'slides.html'
)

$Path = $pscmdlet.GetUnresolvedProviderPathFromPSPath($Path)
$content = Get-Content $Path

$shouldRead = $false
$codeBlocks = for ($i = 0; $i -lt $content.Count; $i++) {
    $line = $content[$i]

    if ($shouldRead -eq $false -and $line.StartsWith('# ')) {
        $header = $line.TrimStart('# ')
    }

    if ($shouldRead -and $line -match '^```$') {
        $shouldRead = $false
        [PSCustomObject]@{
            Header   = $header
            Fragment = $fragment.ToString()
        }
    }

    if ($shouldRead) {
        $null = $fragment.AppendLine($line)
    }

    if ($line -match '^```powershell$') {
        $shouldRead = $true
        $fragment = [System.Text.StringBuilder]::new()
    }
}

$exportContent = foreach ($codeBlock in $codeBlocks) {
    '{{ ## {0}' -f $codeBlock.Header
    $codeBlock.Fragment.Trim()
    '}'
}
Set-Content -Path ($Path -replace '\.[^.]+$', '.ps1') -Value $exportContent