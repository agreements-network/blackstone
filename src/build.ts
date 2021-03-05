import * as fs from "fs";
import * as path from "path";
import * as solc from "solc";
import * as solts from "solts";

const contracts = [
  "active-agreements/TotalCounterCheck.sol",

  "agreements/AgreementsAPI.sol",
  "agreements/ArchetypeRegistry.sol",
  "agreements/Archetype.sol",
  "agreements/ActiveAgreementRegistry.sol",
  "agreements/ActiveAgreement.sol",
  "agreements/DefaultArchetypeRegistry.sol",
  "agreements/ArchetypeRegistryDb.sol",
  "agreements/DefaultActiveAgreementRegistry.sol",
  "agreements/ActiveAgreementRegistryDb.sol",
  "agreements/DefaultArchetype.sol",
  "agreements/DefaultActiveAgreement.sol",
  "agreements/AgreementSignatureCheck.sol",
  "agreements/RenewalWindowManager.sol",
  "agreements/RenewalInitializer.sol",
  "agreements/RenewalEvaluator.sol",
  "agreements/Completables.sol",
  "agreements/AgreementRequestResponse.sol",
  "agreements/DateRelations.sol",
  "agreements/AgreementDates.sol",

  "bpm-model/ProcessModelRepositoryDb.sol",
  "bpm-model/DefaultProcessModelRepository.sol",
  "bpm-model/BpmModelLib.sol",
  "bpm-model/ProcessDefinition.sol",
  "bpm-model/ProcessModelRepository.sol",
  "bpm-model/ProcessModel.sol",
  "bpm-model/DefaultProcessModel.sol",
  "bpm-model/DefaultProcessDefinition.sol",

  "bpm-oracles/DeadlineOracle.sol",
  "bpm-oracles/WaitOracle.sol",

  "bpm-runtime/DefaultApplicationRegistry.sol",
  "bpm-runtime/ApplicationRegistryDb.sol",
  "bpm-runtime/BpmRuntimeLib.sol",
  "bpm-runtime/ProcessInstance.sol",
  "bpm-runtime/ApplicationRegistry.sol",
  "bpm-runtime/BpmService.sol",
  "bpm-runtime/DefaultBpmService.sol",
  "bpm-runtime/BpmServiceDb.sol",
  "bpm-runtime/DefaultProcessInstance.sol",

  "commons-auth/DefaultEcosystem.sol",
  "commons-auth/DefaultUserAccount.sol",
  "commons-auth/DefaultOrganization.sol",
  "commons-auth/ParticipantsManagerDb.sol",
  "commons-auth/DefaultParticipantsManager.sol",
  "commons-auth/EcosystemRegistryDb.sol",
  "commons-auth/DefaultEcosystemRegistry.sol",
  "commons-auth/Organization.sol",
  "commons-auth/EcosystemRegistry.sol",
  "commons-auth/Ecosystem_v1_0_1.sol",
  "commons-auth/ParticipantsManager.sol",
  "commons-auth/UserAccount.sol",

  "commons-base/ErrorsLib.sol",

  "commons-collections/DataStorageUtils.sol",
  "commons-collections/MappingsLib.sol",

  "commons-management/UpgradeOwned.sol",
  "commons-management/DefaultArtifactsRegistry.sol",
  "commons-management/DougProxy.sol",
  "commons-management/OwnedDelegateUnstructuredProxy.sol",
  "commons-management/DefaultDoug.sol",
  "commons-management/DOUG.sol",
  "commons-management/VersionedArtifact.sol",

  "commons-math/Addition.sol",
  "commons-math/Decrement.sol",
  "commons-math/Division.sol",
  "commons-math/GreaterThan.sol",
  "commons-math/GreaterThanEqual.sol",
  "commons-math/Increment.sol",
  "commons-math/IsEqual.sol",
  "commons-math/IsNotEqual.sol",
  "commons-math/LessThan.sol",
  "commons-math/LessThanEqual.sol",
  "commons-math/MakeZero.sol",
  "commons-math/Multiplication.sol",
  "commons-math/Subtraction.sol",

  "commons-standards/ERC165Utils.sol",
  "commons-standards/IsoCountries100.sol",
  "commons-standards/IsoCurrencies100.sol",

  "commons-utils/DataTypesAccess.sol",
  "commons-utils/TypeUtilsLib.sol",
  "commons-utils/ArrayUtilsLib.sol",
  "commons-utils/Strings.sol",

  "migrations/Migrations.sol",
];

const binPath = "bin";

/**
 * This is our Solidity -> Typesciprt, it:
 *  - Compiles Solidity source
 *  - Generates typescript code wrapping the Solidity contracts and functions that calls Burrow
 *  - Generates typescript code to deploy the contracts
 *  - Outputs the ABI files into bin to be later included in the distribution (for Vent and other ABI-consuming services)
 */
function main() {
  fs.mkdirSync(binPath, { recursive: true });
  let inputDescription = solts.InputDescriptionFromFiles(...contracts);
  const input = solts.EncodeInput(inputDescription);
  const solcOutput = solc.compile(input, { import: solts.ImportLocal });
  const output = solts.DecodeOutput(solcOutput);
  if (output.errors && output.errors.length > 0) {
    throw new Error(
      output.errors.map((err) => err.formattedMessage).join("\n")
    );
  }

  for (const filename of Object.keys(output.contracts)) {
    const compiled: solts.Compiled[] = [];
    const solidity = output.contracts[filename];
    for (const contract of Object.keys(solidity)) {
      const comp = output.contracts[filename][contract];
      compiled.push({
        name: contract,
        abi: comp.abi,
        bin: comp.evm.bytecode.object,
        links: solts.TokenizeLinks(comp.evm.bytecode.linkReferences),
      });
    }
    const target = filename.replace(/\.[^/.]+$/, ".abi.ts");
    const basename = path.basename(filename, ".sol");
    // Write the ABIs emitted for each file to the name of that file without extension. We flatten into a single
    // directory because that's what burrow deploy has always done.
    fs.writeFileSync(
      path.join(binPath, basename + ".bin"),
      JSON.stringify(solidity[basename])
    );
    fs.writeFileSync(target, solts.Print(...solts.NewFile(compiled)));
  }
}

main();
