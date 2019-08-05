```
/$$       /$$                     /$$                   /$$
| $$      | $$                    | $$                  | $$
| $$$$$$$ | $$  /$$$$$$   /$$$$$$$| $$   /$$  /$$$$$$$ /$$$$$$    /$$$$$$  /$$$$$$$   /$$$$$$
| $$__  $$| $$ |____  $$ /$$_____/| $$  /$$/ /$$_____/|_  $$_/   /$$__  $$| $$__  $$ /$$__  $$
| $$  \ $$| $$  /$$$$$$$| $$      | $$$$$$/ |  $$$$$$   | $$    | $$  \ $$| $$  \ $$| $$$$$$$$
| $$  | $$| $$ /$$__  $$| $$      | $$_  $$  \____  $$  | $$ /$$| $$  | $$| $$  | $$| $$_____/
| $$$$$$$/| $$|  $$$$$$$|  $$$$$$$| $$ \  $$ /$$$$$$$/  |  $$$$/|  $$$$$$/| $$  | $$|  $$$$$$$
|_______/ |__/ \_______/ \_______/|__/  \__/|_______/    \___/   \______/ |__/  |__/ \_______/
```

<table>
  <tr>
    <td>The <strong>Blackstone</strong> codebase is a collection of smart contracts and RESTful APIs which together form the basis for the Agreements Network.
    <br/><br/>
    It is named after <a href="https://en.wikipedia.org/wiki/William_Blackstone">Sir William Blackstone</a>, an English jurist, judge, and politician of the eighteenth century.
    <br/><br/>
    This collection includes a full-feature business process execution engine, and high-level translator from BPMN standard to smart contract based process graphs. It also include an object management suite utilized by the Agreements Network.</td>
    <td><img src="https://upload.wikimedia.org/wikipedia/commons/a/a6/SirWilliamBlackstone.jpg" width="220px"/></td>
  </tr>
</table>

## Preliminary Note

While the code in this repository is geared towards its use in the [Agreements Network](https://agreements.network), the lower-level functions and smart contracts are highly reusable and suited to build any blockchain-based ecosystem application. If you would like to learn more about the interfaces used in this system please visit the [documentation site](https://docs.agreements.network) for the network.

To ask questions or to learn more feel free to join the [Agreements Network mailing list](https://lists.agreements.network) to ask questions or to join the community.

# Table of Contents
1. [Quick Start](#QuickStart)
2. [First Steps](#FirstSteps)
3. [Tutorials](#Tutorials)
3. [Develop & Test](#DevelopAndTest)

# <a name="QuickStart">Quick Start</a>

It's highly recommended to use `docker-compose` as described below to run all of the commands. This saves installation problems and environment problems between developers. (All commands should be run from the root of this repo.)

### Prerequisites

Install `make`, `docker`, and `docker-compose`. Now you're ready to go.

### Go VROOM!

The following commands will start a Burrow Blockchain, compile, deploy and wire all smart contracts and boot the Node.js API.

To start from a completely clean repo (includes `npm install`):

```bash
make run_all
```

To start from a repo that already has `node_modules`:

```bash
make run
```

Now, the API is available at `http://localhost:3080`.


# <a name="FirstSteps">First Steps</a>

The following serious of steps outlines basic interactions with the Blackstone API:

### Create a user

`POST http://localhost:3080/users`

Body (`application/json`):

```json
{
	"user": "john.smith",
	"email": "john.smith@example.com",
	"password": "298yefh028"
}
```

Response:

```json
{
    "address": "AB3399395E9CAB5434022D1992D31BB3ACC2E3F1",
    "username": "john.smith"
}
```

### Login

`PUT http://localhost:3080/users/login`

Body (`application/json`):

```json
{
	"user": "john.smith",
	"password": "298yefh028"
}
```

A successful login creates a Json Web Token `access_token` that can be used for any subsequent requests using this user's session.

### Deploy a BPMN process model

Use the BPMN model [here](docs/files/QuickStartModel.bpmn) as `application/xml` body to the endpoint:

`POST http://localhost:3080/bpm/process-models`

Part of the `application/json` response gives you the information about the deployed processes `Agreement Formation` and `Agreement Execution`. Note the `address` fields of the two created processes:

```json
"model": {
    "id": "1537809995472_Gc4N66ORqT",
    "address": "81420B0BD90FBDA9765207569DA0FF6D4A429F65"
},
"processes": [
    {
        "processDefinitionId": "Process_104nkeu",
        "interfaceId": "Agreement Formation",
        "processName": "Sale Formation",
        "modelAddress": "81420B0BD90FBDA9765207569DA0FF6D4A429F65",
        "address": "09F5727636788958DAEF32500830F0AD4EB34901",
        "private": false,
        "author": "AB3399395E9CAB5434022D1992D31BB3ACC2E3F1"
    },
    {
        "processDefinitionId": "Process_0gzkjfe",
        "interfaceId": "Agreement Execution",
        "processName": "Sale Execution",
        "modelAddress": "81420B0BD90FBDA9765207569DA0FF6D4A429F65",
        "address": "E6534E45E2B26AF4FBB64E42CE7FC66688696483",
        "private": false,
        "author": "AB3399395E9CAB5434022D1992D31BB3ACC2E3F1"
    }
],
```

### Create an Agreement Archetype

Now we can make an archetype for new agreements by calling

`POST http://localhost:3080/archetypes`

Body (`application/json`):

```json
{
    "name": "My Sales Archetype",
    "description": "A template agreement for the sale of goods between a Buyer and a Seller",
    "price": "5.99",
    "isPrivate": false,
    "active": true,
    "parameters": [
        { "type": 8, "name": "Buyer", "signatory": true },
        { "type": 8, "name": "Seller", "signatory": true },
        { "type": 1, "name": "Item Description" },
        { "type": 5, "name": "Price" }
    ],
    "documents": [],
    "jurisdictions": [
        {
        "country": "US",
        "regions": []
        }
    ],
    "formationProcessDefinition": "09F5727636788958DAEF32500830F0AD4EB34901",
    "executionProcessDefinition": "E6534E45E2B26AF4FBB64E42CE7FC66688696483"
}
```

This will return the address of the new archetype for reference:

```json
{
    "address": "4EF5DAB8CE089AD7F2CE7A04A7CB5DB1C58DB707"
}
```

### Instantiate an Agreemeent

Now we can go ahead and create an actual legal agreement based on the information we've configured in the system so far.
Note that we're using the currently logged-in user as both the "Buyer" and "Seller" for demo purposes only; in a real-world legal context that would not be a valid.

`POST http://localhost:3080/agreements`

Body (`application/json`):

```json
{
  "name": "Sale No. 7364",
  "archetype": "4EF5DAB8CE089AD7F2CE7A04A7CB5DB1C58DB707",
  "isPrivate": false,
  "maxNumberOfEvents": "10",
  "parameters": [{
      "name": "Buyer",
      "type": 8,
      "value": "AB3399395E9CAB5434022D1992D31BB3ACC2E3F1"
    },
    {
      "name": "Seller",
      "type": 8,
      "value": "AB3399395E9CAB5434022D1992D31BB3ACC2E3F1"
    },
    {
      "name": "Item Description",
      "value": "Lamborghine (red, 2016)"
    },
    {
      "name": "Price",
      "value": "160000.00"
    }
  ]
}
```

This will return the address of the new archetype for reference:

```json
{
    "address": "B3AEAD4717EFF80BDDF5E22110521029A8460FFB"
}
```

You can use the returned address to show the status and information about your agreement:

`GET http://localhost:3080/agreements/B3AEAD4717EFF80BDDF5E22110521029A8460FFB`

### Participate in the agreement workflow

According to the Process Definition covering the formation of this sales agreement, both parties have to complete the "Sign Agreement" task by signing the agreement. Since we used the same user for demo purposes, the user's task list will show two items:

`GET http://localhost:3080/tasks`

```json
[
    {
        "state": 4,
        "processAddress": "A2927604F47D45CC518557A9C31E5EACB9EF8AC5",
        "activityInstanceId": "4C5381C1AB820779B897DAA64378C20D2475EC7535691B805AC02C0346E339B6",
        "activityId": "Task_0ky8n9d",
        "created": 1537813661000,
        "performer": "AB3399395E9CAB5434022D1992D31BB3ACC2E3F1",
        "modelAddress": "81420B0BD90FBDA9765207569DA0FF6D4A429F65",
        "modelId": "1537809995472_Gc4N66ORqT",
        "processDefinitionAddress": "09F5727636788958DAEF32500830F0AD4EB34901",
        "processDefinitionId": "Process_104nkeu",
        "agreementAddress": "B3AEAD4717EFF80BDDF5E22110521029A8460FFB",
        "agreementName": "Sale No. 7364",
        "name": "Sign Agreement",
        "processName": "Sale Formation"
    },
    {
        "state": 4,
        "processAddress": "A2927604F47D45CC518557A9C31E5EACB9EF8AC5",
        "activityInstanceId": "42B546051E099604F7AEAD7A3447C646E7EFF9ACFAB90B71CC89408023124F75",
        "activityId": "Task_0ky8n9d",
        "created": 1537813661000,
        "performer": "AB3399395E9CAB5434022D1992D31BB3ACC2E3F1",
        "modelAddress": "81420B0BD90FBDA9765207569DA0FF6D4A429F65",
        "modelId": "1537809995472_Gc4N66ORqT",
        "processDefinitionAddress": "09F5727636788958DAEF32500830F0AD4EB34901",
        "processDefinitionId": "Process_104nkeu",
        "agreementAddress": "B3AEAD4717EFF80BDDF5E22110521029A8460FFB",
        "agreementName": "Sale No. 7364",
        "name": "Sign Agreement",
        "processName": "Sale Formation"
    }
]
```

Each of these tasks can be completed using the following endpoint.
Note: This URL is a shortcut for _signing_ the agreement and _completing_ the workflow task in one call.

`PUT http://localhost:3080/tasks/4C5381C1AB820779B897DAA64378C20D2475EC7535691B805AC02C0346E339B6/complete/B3AEAD4717EFF80BDDF5E22110521029A8460FFB/sign`

`PUT http://localhost:3080/tasks/42B546051E099604F7AEAD7A3447C646E7EFF9ACFAB90B71CC89408023124F75/complete/B3AEAD4717EFF80BDDF5E22110521029A8460FFB/sign`

Signing and completing both these tasks also completes the Formation of the agreement. If you retrieve the details about the agreement, you'll see that the legal state has switched to *Executed* (`legalState: 2`).

`GET http://localhost:3080/agreements/B3AEAD4717EFF80BDDF5E22110521029A8460FFB`


# <a name="Tutorials">Tutorials</a>

### Tools (coming soon)

Provides an overview of the tools, specifically how the Agreements Network leverages `burrow deploy`. This will help users understand how to deploy and wire smart contracts utilizing `burrow`.

### Smart Contract Framework (coming soon)

Delivers an introduction to the smart contracts in this project and walks through the concepts to deploy a basic framework of upgradeable packages of smart contracts wired together as micro-services in order to build applications.

### My Application (coming soon)

Build a web app to interact with your archetypes and active agreements.


# <a name="DevelopAndTest">Develop & Test</a>

The following sections provide an overview over commands helpful for developing and testing Blackstone smart contracts and API functions.

Blackstone has two main components - the Node.js API in api/ and the Solidity contracts in contracts/. Testing is scripted in the Makefile. To handle different environments the build/test/deploy scripts for contracts and the API reads values from the environment.

Defaults values for the environments can be found in the `local.env` and `dev.env` environment files. The former is designed to be used where working locally, to you use it run `source local.env` from a terminal which will export all the variables for use by targets you subsequently call. `dev.env` is used by the docker-compose 'API' container which is used to test in CI (and can be used locally).

Blackstone also depends on a cluster of dependency services, namely: Burrow, Postgres, and Vent. It is convenient to run these using docker-compose.yml, but the developer test loop is improved by running the contract test and deployment and API locally, since they are the systems actively under development.

### Prerequisites

#### Install Burrow

https://github.com/hyperledger/burrow/blob/master/docs/INSTALL.md

#### Install Solc

On MacOS:
```
brew install boost@1.60
brew install https://raw.githubusercontent.com/ethereum/homebrew-ethereum/f26f126820e5f47c3ed7ec6d5e6e046707443d87/solidity.rb
```

If you already had `boost` installed in a higher version, you need to downgrade to the 1.60 version by running the following:

```
brew unlink boost
brew link --force boost@1.60
```

### Running locally
To run locally you will need to have [`burrow`](https://github.com/hyperledger/burrow/releases) (for `burrow deploy`) and [`solc`](https://github.com/ethereum/solidity/releases/tag/v0.4.25) installed, from the project root:

```bash
# Set up environment
source local.env
# Run dependency services (these remain running - you can take them down with make down)
make docker_run_deps
# Build contracts and run all tests
make test

```

### Running in docker-compose

```bash
# The same as test but everything is run in docker-compose (included NPM and burrow deploy)
make docker_test
# To run other make targets within a reproducible docker container (that don't explicitly call docker-compose themselves) run:
docker-compose run api make $TARGET
```

### Running elsewhere
Just ensure that the environment variables listed in `dev.env` are configured in the environment you are using.

#### Test All

To run the **entire** test suite run the following.

```bash
make test
```

#### Test Bundles

To run the test step for a single bundle of contracts run the following. **N.B.** in the following command no spaces are entered between the target bundles. To only run one bundle do not enter a comma.

```bash
make test_contracts tgt=agreements,bpm-runtime
```

To run the test step for all the bundles of contracts run the following:

```bash
make test_contracts
```

### Work with the API

To run the npm install for the API run the following:

```bash
make install_api
```

To run the API test suite (without installing NPM or the bundles) run the following:

```bash
make test_api
```

To start the API:

```bash
npm --prefix api run-script start:dev
```

### Cleanup

To run the clean step in docker (useful for clearing caches and reseting defaults) run the following:

```bash
make clean
```

To clean the **entire** system (including node_modules and bundle_cache) run the following:

```bash
make clean_all
```

### Development command examples

#### Run pending migrations

```bash
cd api
npm run db:migrate:up
```

#### Run manual upgrade of contracts
Run a yaml script, e.g. a manual upgrade.

```bash
cd contracts/src
burrow deploy --chain=localhost:10997 --address=<deployment-address> --bin-path ./bin ../upgrades/NewServiceUpgrade-1.2.7.yaml
```
