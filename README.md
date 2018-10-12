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

While the code in this repository is geared towards its use in the [Agreements Network](https://agreements.network), the lower-level functions and smart contracts are highly reusable and suited to build any blochchain-based ecosystem application. If you would like to learn more about the interfaces used in this system please visit the [documentation site](https://docs.agreements.network) for the network.

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
    "id": "john.smith"
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

### Test All

To run the **entire** test suite run the following. **N.B.** -- this will take forever.

```bash
make test
```

### Test Bundles

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

To restart the API but leave the chain running follow this sequence:

1. `make run` -> this operation is non-blocking and will return you to your terminal. It will background processes that will follow the logs.
2. To turn everything off (including the chain) from here run `make clean`.
3. To only reboot the API but leave the chain running from here run `make restart_api`. This is a *blocking* call and will not return you to your terminal.
4. To reboot the API (again): `ctrl+c` then `make restart_api`. Rinse and repeat as needed.
5. To turn everything off or reset the chain or whatever: `ctrl+c` then `make clean`.

### Cleanup

To run the clean step in docker (useful for clearing caches and reseting defaults) run the following:

```bash
make clean
```

To clean the **entire** system (including node_modules and bundle_cache) run the following:

```bash
make clean_all
```

### Work Manually

Finally, if you'd like to run the commands one by one to debug, you can go into the bash of the docker container with the following command and then run the commands individually as if you were in the linux local console.

Create a new docker container and open bash

```bash
docker-compose run --service-ports chain bash
```

Prerequisites, if running for the first time:

```bash
cd api
npm install
```

Run pending migrations

```bash
npm run db:migrate:up:dev
```

The node application is now ready to run

```bash
npm run start
```

When you're finished working, then run the clean functions (note, this should be done rarely when in active development):

```bash
docker-compose rm --force --stop
```

From the project root directory, you can also run the tests, e.g.

```
./test/test_api.sh deploy
```

deploys the AN contracts, and leaves the contracts and chain intact. Afterwards:

```
cd api
npm run test
```

