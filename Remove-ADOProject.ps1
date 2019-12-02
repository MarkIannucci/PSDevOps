﻿function Remove-ADOProject
{
    <#
    .Synopsis
        Removes projects from Azure DevOps.
    .Description
        Removes projects in Azure DevOps or TFS.
    .Link
        https://docs.microsoft.com/en-us/rest/api/azure/devops/processes/states/delete?view=azure-devops-rest-5.1
    .Example        
        Remove-ADOProject -Organization StartAutomating -Project TestProject1 -PersonalAccessToken $pat
    #>
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    param(
    # The name or ID of the project.
    [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
    [Alias('ProjectName', 'ProjectID','ID')]
    [string]
    $NameOrID,

    # The Organization
    [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
    [Alias('Org')]
    [string]
    $Organization,

    # The server.  By default https://dev.azure.com/.
    # To use against TFS, provide the tfs server URL (e.g. http://tfsserver:8080/tfs).
    [Parameter(ValueFromPipelineByPropertyName)]
    [uri]
    $Server = "https://dev.azure.com/",

    # The api version.  By default, 5.1.
    # If targeting TFS, this will need to change to match your server version.
    # See: https://docs.microsoft.com/en-us/azure/devops/integrate/concepts/rest-api-versioning?view=azure-devops
    [string]
    $ApiVersion = "5.1",

    # A Personal Access Token
    [Alias('PAT')]
    [string]
    $PersonalAccessToken,

    # Specifies a user account that has permission to send the request. The default is the current user.
    # Type a user name, such as User01 or Domain01\User01, or enter a PSCredential object, such as one generated by the Get-Credential cmdlet.
    [pscredential]
    [Management.Automation.CredentialAttribute()]
    $Credential,

    # Indicates that the cmdlet uses the credentials of the current user to send the web request.
    [Alias('UseDefaultCredential')]
    [switch]
    $UseDefaultCredentials,

    # Specifies that the cmdlet uses a proxy server for the request, rather than connecting directly to the Internet resource. Enter the URI of a network proxy server.
    [uri]
    $Proxy,

    # Specifies a user account that has permission to use the proxy server that is specified by the Proxy parameter. The default is the current user.
    # Type a user name, such as "User01" or "Domain01\User01", or enter a PSCredential object, such as one generated by the Get-Credential cmdlet.
    # This parameter is valid only when the Proxy parameter is also used in the command. You cannot use the ProxyCredential and ProxyUseDefaultCredentials parameters in the same command.
    [pscredential]
    [Management.Automation.CredentialAttribute()]
    $ProxyCredential,

    # Indicates that the cmdlet uses the credentials of the current user to access the proxy server that is specified by the Proxy parameter.
    # This parameter is valid only when the Proxy parameter is also used in the command. You cannot use the ProxyCredential and ProxyUseDefaultCredentials parameters in the same command.
    [switch]
    $ProxyUseDefaultCredentials
    )

    begin {
        #region Copy Invoke-ADORestAPI parameters
        # Because this command wraps Invoke-ADORestAPI, we want to copy over all shared parameters.
        $invokeRestApi = # To do this, first we get the commandmetadata for Invoke-ADORestAPI.
            [Management.Automation.CommandMetaData]$ExecutionContext.SessionState.InvokeCommand.GetCommand('Invoke-ADORestAPI', 'Function')

        $invokeParams = @{} + $PSBoundParameters # Then we copy our parameters
        foreach ($k in @($invokeParams.Keys)) {  # and walk thru each parameter name.
            # If a parameter isn't found in Invoke-ADORestAPI
            if (-not $invokeRestApi.Parameters.ContainsKey($k)) {
                $invokeParams.Remove($k) # we remove it.
            }
        }
        # We're left with a hashtable containing only the parameters shared with Invoke-ADORestAPI.
        #endregion Copy Invoke-ADORestAPI parameters

    }
    process {
        $uri = @(
            "$Server".TrimEnd('/')
            $Organization
            '_apis'
            'projects'
            if ($NameOrID -as [guid]) {
                $NameOrID
            } else {
                $myParams = @{} + $PSBoundParameters
                $myParams.Remove('WhatIf')
                $myParams.Remove('Confirm')
                Get-ADOProject @myParams | Select-Object -First 1 -ExpandProperty ID
            }
        ) -join '/'
        $uri += '?'
        if ($ApiVersion) {
            $uri += "api-version=$ApiVersion"
        }
       
        if (-not $PSCmdlet.ShouldProcess("DELETE $uri")) { return } 
        Invoke-ADORestAPI @invokeParams -uri $uri -Method DELETE
    }
}