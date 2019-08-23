function Search-UrlScanio {
<#
.SYNOPSIS
Search urlscan.io

.DESCRIPTION
Search urlscan.io using the provided parameters or providing a filter using Elasticsearch Query String syntax
(https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-query-string-query.html)

Params specified are combined to form a valid filter string.

.PARAMETER Domain
Domain to return results for (equivilent to page.domain)

.PARAMETER IP
Limit results or return those which are related to the IP provided

.PARAMETER ASN
Limit results or return those which are related to the ASN provided

.PARAMETER ASNName
Limit results or return those which are related to the ASN Name provided

.PARAMETER Filename
Limit results or return those which are related to the file name provided

.PARAMETER Hash
Limit results or return those which are related to the hash provided

.PARAMETER Server
Limit results or return those which are related to the server provided

.PARAMETER Filter
Filter string

.PARAMETER Limit
Number of results to return (default 100)

.PARAMETER Raw
Return results as raw json

.EXAMPLE
Search-UrlScanio -Domain google.com -Limit 10
Returns last 10 scans completed on the domain google.com
#>

    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = 'Filter')]
        [string]$Filter,

        [Parameter(ParameterSetName = 'Params')]
        [string]$Domain,
        [Parameter(ParameterSetName = 'Params')]
        [string]$IP,
        [Parameter(ParameterSetName = 'Params')]
        [string]$ASN,
        [Parameter(ParameterSetName = 'Params')]
        [string]$ASNName,
        [Parameter(ParameterSetName = 'Params')]
        [string]$Filename,
        [Parameter(ParameterSetName = 'Params')]
        [string]$Hash,
        [Parameter(ParameterSetName = 'Params')]
        [string]$Server,

        [int]$Limit = 100,
        [switch]$Raw
    )

    process {
        if ($PSBoundParameters.Count -eq 0) {
            Write-Error "Please provide search criteria."
        }

        if ($PSCmdlet.ParameterSetName -eq 'Filter') {
            $query = $filter
        } elseif ($PSCmdlet.ParameterSetName -eq 'Params') {
            # query builder
            $query = @()
            $PSBoundParameters.GetEnumerator() | % {
                if (($_.Key -ne 'Limit') -and ($_.Key -ne 'Raw')) {
                    $k = $_.Key.ToLower()
                    $v = $_.Value.ToLower()

                    if ($_.Key -eq 'Domain') { $k = 'page.domain' }
                    $query += $k + ':' + $v
                }
            }

            if ($query.count -ge 2) {
                $query = $query -join ' AND '
            }
        }

        $url = "https://urlscan.io/api/v1/search/?q=$query" + "&size=$Limit"
        $request = Invoke-RestMethod -Uri $url -Headers $headers -ErrorAction:Stop
        $results = $request.results

        if ($PSBoundParameters.Raw) { # return raw json if called
            $out = $results | ConvertTo-Json
        } else {
            $out = $results | % {
                [PSCustomObject]@{
                    TaskDate = $_.task.time
                    Submission = $_.task.method
                    uuid = $_._id
                    URL = $_.page.url
                    ApiResult = $_.result
                    ResultPage = $_.result -replace '/api/v1'
                }
            } | sort TaskDate
        }
    }

    end {
        return $out
    }
}