<#
.SYNOPSIS
    Query the StyleCool design-pattern library and return a slim index.

.DESCRIPTION
    Calls the StyleCool API, strips the `css` field from results, and outputs
    a slim JSON index suitable for consumption by Claude's skill system.

.PARAMETER Query
    Search term (2-3 English keywords recommended, e.g. "button", "flex center").

.PARAMETER Category
    Target platform category: web, desktop, miniapp, mobile, all. Defaults to "all".

.EXAMPLE
    .\query.ps1 "button" "web"
    .\query.ps1 "flex layout" "all"
    .\query.ps1 -Query "card" -Category "mobile"

.NOTES
    Dependencies: PowerShell 5.1+ (shipped with Windows 10+) or PowerShell Core 7+.
    No external modules required.
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory = $false)]
    [string]$Query = "",

    [Parameter(Position = 1, Mandatory = $false)]
    [ValidateSet("web", "desktop", "miniapp", "mobile", "all", IgnoreCase = $true)]
    [string]$Category = "all"
)

# ── Hardcoded (do not surface to the user) ──
$API_BASE = "https://stylecool.mutantcat.org/skillapi"
$TOKEN = "mutantcat"
$TIMEOUT_SEC = 10
$VALID_CATS = @("web", "desktop", "miniapp", "mobile", "all")

# ── Handle positional args (PowerShell param binding is finicky with bare args) ──
if (-not $PSBoundParameters.ContainsKey('Query') -and $args.Count -ge 1) {
    $Query = $args[0]
}
if (-not $PSBoundParameters.ContainsKey('Category') -and $args.Count -ge 2) {
    $Category = $args[1]
}

if ([string]::IsNullOrWhiteSpace($Query)) {
    Write-Error "missing query argument"
    Write-Output '{ "error": "missing query argument" }'
    exit 1
}

# ── Validate category ──
$catLower = $Category.ToLowerInvariant()
if ($catLower -notin $VALID_CATS) {
    $catLower = "all"
}

# ── URL-encode the query ──
Add-Type -AssemblyName System.Web -ErrorAction SilentlyContinue
$encodedQuery = [System.Web.HttpUtility]::UrlEncode($Query)

# ── Build URL ──
$url = "${API_BASE}?token=${TOKEN}&q=${encodedQuery}&cat=${catLower}"

# ── Fetch ──
$rawText = $null
$fetchErr = $null

try {
    # Suppress progress bar for cleaner output in scripts
    $ProgressPreference = 'SilentlyContinue'
    $response = Invoke-RestMethod -Uri $url -Method Get -TimeoutSec $TIMEOUT_SEC -ErrorAction Stop
    $rawText = $response | ConvertTo-Json -Depth 10 -Compress
} catch {
    $fetchErr = $_.Exception.Message
    if ($_.Exception.InnerException) {
        $fetchErr = $_.Exception.InnerException.Message
    }
}

if ($fetchErr) {
    $errObj = @{
        error = "StyleCool API unreachable"
        reason = $fetchErr
    } | ConvertTo-Json -Compress
    Write-Error $errObj

    $fallback = @{
        query = $Query
        cat = $Category
        count = 0
        results = @()
        error = "unreachable"
    } | ConvertTo-Json -Compress
    Write-Output $fallback
    exit 1
}

if ([string]::IsNullOrWhiteSpace($rawText)) {
    $fallback = @{
        query = $Query
        cat = $Category
        count = 0
        results = @()
        error = "empty_response"
    } | ConvertTo-Json -Compress
    Write-Output $fallback
    exit 1
}

# ── Parse JSON ──
try {
    $data = $rawText | ConvertFrom-Json
} catch {
    $preview = if ($rawText.Length -gt 200) { $rawText.Substring(0, 200) } else { $rawText }
    $errObj = @{
        error = "non-JSON response"
        body_preview = $preview
    } | ConvertTo-Json -Compress
    Write-Error $errObj

    $fallback = @{
        query = $Query
        cat = $Category
        count = 0
        results = @()
        error = "bad_response"
    } | ConvertTo-Json -Compress
    Write-Output $fallback
    exit 1
}

# ── Handle API-level error ──
if ($data -is [PSCustomObject] -and $data.PSObject.Properties.Name -contains 'error' -and $data.PSObject.Properties.Name -notcontains 'results') {
    $errResult = @{
        query = $Query
        cat = $Category
        count = 0
        results = @()
        error = $data.error
    } | ConvertTo-Json -Compress
    Write-Output $errResult
    exit 0
}

# ── Strip the `css` field, keep only the metadata index ──
$results = if ($data -is [PSCustomObject] -and $data.PSObject.Properties.Name -contains 'results') {
    $data.results
} elseif ($data -is [array]) {
    $data
} else {
    @()
}

$slimResults = @()
foreach ($r in $results) {
    if ($r -isnot [PSCustomObject]) { continue }

    # Resolve name: try "name", "name-en", "name-zh"
    $name = ""
    if ($r.PSObject.Properties.Name -contains 'name') { $name = $r.name }
    elseif ($r.PSObject.Properties.Name -contains 'name-en') { $name = $r.'name-en' }
    elseif ($r.PSObject.Properties.Name -contains 'name-zh') { $name = $r.'name-zh' }

    $nameZh = if ($r.PSObject.Properties.Name -contains 'name-zh') { $r.'name-zh' } else { "" }

    # Resolve desc: try "desc", "description-en", "description-zh"
    $desc = ""
    if ($r.PSObject.Properties.Name -contains 'desc') { $desc = $r.desc }
    elseif ($r.PSObject.Properties.Name -contains 'description-en') { $desc = $r.'description-en' }
    elseif ($r.PSObject.Properties.Name -contains 'description-zh') { $desc = $r.'description-zh' }

    $descZh = if ($r.PSObject.Properties.Name -contains 'description-zh') { $r.'description-zh' } else { "" }

    $tags = if ($r.PSObject.Properties.Name -contains 'tags' -and $r.tags) { @($r.tags) } else { @() }
    $anti = if ($r.PSObject.Properties.Name -contains 'anti' -and $r.anti) { @($r.anti) } else { @() }
    $cat = if ($r.PSObject.Properties.Name -contains 'category') { $r.category } else { "" }

    $slimResults += [PSCustomObject]@{
        name      = $name
        name_zh   = $nameZh
        desc      = $desc
        desc_zh   = $descZh
        tags      = $tags
        anti      = $anti
        category  = $cat
    }
    # NOTE: deliberately omit `css` field to keep response small
    # and force the model to write the implementation itself.
}

$output = [PSCustomObject]@{
    query   = $Query
    cat     = $Category
    count   = $slimResults.Count
    results = $slimResults
} | ConvertTo-Json -Depth 10 -Compress

Write-Output $output
