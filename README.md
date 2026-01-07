
# Azure-AVNM (Bicep)

Deploys an Azure Virtual Network Manager (AVNM) environment using Bicep, with a per-region pattern for:

- Hub + spoke virtual networks
- AVNM Network Groups
- AVNM Connectivity Configurations (Hub-and-Spoke)
- Optional policy definitions/assignments to manage network group membership

This repo is designed to be deployed at **subscription scope** via `main.bicep`.

## What gets deployed

At a high level:

1. A resource group (default name is typically `rg-avnm`)
2. An AVNM instance (Network Manager)
3. For each configured region:
	 - Virtual networks (hub + spokes)
	 - A network group
	 - (Optional) policy definitions/assignments used for dynamic group membership
	 - A connectivity configuration that applies to the network group

> Notes
> - AVNM configurations still need to be **deployed/committed to regions** for effects to take place. Creating a connectivity configuration defines intent; deployment/commit is what applies it.

## Repo layout

- `main.bicep`: Subscription-scope entrypoint
- `modules/`: Building blocks used by `main.bicep`
	- `modules/perRegion.bicep`: Orchestrates a single region (VNets, NG, connectivity, policy, etc.)
	- `modules/vnets.bicep`: Creates hub/spoke VNets and returns resource IDs
	- `modules/avnm.bicep`: Creates the Network Manager
	- `modules/avnmNg.bicep`: Creates a Network Group
	- `modules/avnmConnectivity.bicep`: Creates the connectivity configuration (connectivityConfigurations)
	- `modules/avnmNgPolicyDef.bicep`: Policy definition(s) used for membership (if enabled)
	- `modules/avnmNgPolicyAssign.bicep`: Policy assignment(s) that target VNets (if enabled)
	- Other helper modules (e.g., hubs variants)

## Prerequisites

### Azure

- An Azure subscription where you can deploy at subscription scope
- Permissions:
	- Create resource groups
	- Create Network Manager resources
	- Create VNets and peerings (created later when connectivity is deployed)
	- Create/assign policies (if using the policy modules)

### Tooling

- Bicep CLI (either standalone or via Azure CLI/Az tooling)
- PowerShell 7+ recommended
- Az PowerShell modules:
	- `Az.Accounts`
	- `Az.Resources`
	- `Az.Network`

## Quick start (PowerShell)

From the repo root:

```powershell
# Sign in and select subscription (if needed)
Connect-AzAccount
Set-AzContext -Subscription <subscriptionId>

# Deploy the template at subscription scope
New-AzSubscriptionDeployment \
	-Name avnm \
	-Location SwedenCentral \
	-TemplateFile .\main.bicep \
	-Verbose
```

### Idempotency

This template is intended to be re-runnable. Re-running typically updates resources in-place.

## Parameters

Parameters are defined primarily in `main.bicep` and passed into regional modules.

Common knobs you’ll see in the modules:

- **AVNM name** (`avnmName`): Name of the Network Manager
- **Region list / locations**: Determines which `perRegion` modules are deployed
- **Connectivity configuration name** (`connectivityConfigName`): Typically includes the region
- **Connectivity topology** (`connectivitytopology`): `HubAndSpoke` or `Mesh`
- **Group connectivity** (`groupConnectivity`): `None` or `DirectlyConnected`
- **Use hub gateway** (`useHubGateway`): `True`/`False` (string per ARM schema)
- **Delete existing peerings** (`deleteExistingPeering`): `True`/`False` (string per ARM schema)

If you want to override parameters, use the standard Az deployment pattern:

```powershell
New-AzSubscriptionDeployment \
	-Name avnm \
	-Location SwedenCentral \
	-TemplateFile .\main.bicep \
	-TemplateParameterObject @{
		# Example (only if main.bicep exposes these as params)
		# avnmName = 'AVNM01'
	}
```

## How connectivity is modeled (important)

The connectivity configuration is created under:

`Microsoft.Network/networkManagers/connectivityConfigurations`

and uses the **hubs array** when in Hub-and-Spoke mode.

### Hub payload shape

The hub entry must use the correct `resourceType`:

```json
{
	"resourceId": "/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/<hubVnet>",
	"resourceType": "Microsoft.Network/virtualNetworks"
}
```

If you provide an unexpected value for `resourceType`, ARM may return an internal error during deserialization/mapping.

## Validate what was deployed

### Check the subscription deployment

```powershell
Get-AzSubscriptionDeployment -Name avnm | Select-Object ProvisioningState, CorrelationId, Timestamp
```

### Check the AVNM exists

```powershell
Get-AzNetworkManager -ResourceGroupName rg-avnm | Select-Object Name, Location, ProvisioningState
```

### Check connectivity configurations

```powershell
Get-AzNetworkManagerConnectivityConfiguration -ResourceGroupName rg-avnm -NetworkManagerName <avnmName>
```

You should see properties such as `ConnectivityTopology`, `AppliesToGroupsText`, and `HubsText`.

## Troubleshooting

### Deployment fails with internal mapping/deserialization errors

Symptoms may include ARM errors like:

- `InternalServerError`
- Messages similar to: “Error mapping types… Destination Member: Properties”

Recommended actions:

1. **Verify your hub object shape**: `hubs[].resourceType` should be `Microsoft.Network/virtualNetworks`.
2. **Use a known-stable API version** for `connectivityConfigurations`.

In this repo, `modules/avnmConnectivity.bicep` uses:

- `Microsoft.Network/networkManagers@2022-11-01` (existing parent)
- `Microsoft.Network/networkManagers/connectivityConfigurations@2022-11-01`

This aligns with the stable schema where many boolean-like fields are actually represented as `"True"`/`"False"` strings.

### Deployment shows “Canceled” on a nested deployment

This usually means a nested deployment was canceled due to a failure in an earlier operation. To identify the real error:

```powershell
$rg = 'rg-avnm'
$dep = 'perRegion-swedencentral'
Get-AzResourceGroupDeploymentOperation -ResourceGroupName $rg -DeploymentName $dep |
	Select-Object OperationId, ProvisioningState, StatusCode, TargetResource, StatusMessage
```

Look for operations that are `Failed` or show a `StatusMessage` indicating which nested deployment/resource caused the cascade.

## Development notes

### Build the ARM JSON locally

```powershell
bicep build .\main.bicep
```

This produces `main.json` in the repo root.

If you don’t want generated artifacts committed, add `main.json` to `.gitignore`.

## Security / cost

- This template creates network resources that may incur cost (VNets themselves are generally free; gateways, firewalls, and traffic are not).
- Review the modules before deploying to production subscriptions.

## Contributing

- Keep module inputs/outputs explicit.
- Prefer stable API versions when providers show regression behavior.
- Run `bicep build` before submitting changes.

