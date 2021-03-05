import { Client } from "./lib/client";

import { ErrorsLib } from "./commons-base/ErrorsLib.abi";
import { TypeUtilsLib } from "./commons-utils/TypeUtilsLib.abi";
import { ArrayUtilsLib } from "./commons-utils/ArrayUtilsLib.abi";
import { MappingsLib } from "./commons-collections/MappingsLib.abi";
import { DataStorageUtils } from "./commons-collections/DataStorageUtils.abi";
import { ERC165Utils } from "./commons-standards/ERC165Utils.abi";
import { BpmModelLib } from "./bpm-model/BpmModelLib.abi";
import { BpmRuntimeLib } from "./bpm-runtime/BpmRuntimeLib.abi";
import { AgreementsAPI } from "./agreements/AgreementsAPI.abi";
import { DataTypesAccess } from "./commons-utils/DataTypesAccess.abi";
import { Strings } from "./commons-utils/Strings.abi";

import { DefaultDoug } from "./commons-management/DefaultDoug.abi";
import { DougProxy } from "./commons-management/DougProxy.abi";
import { DOUG } from "./commons-management/DOUG.abi";
import { DefaultArtifactsRegistry } from "./commons-management/DefaultArtifactsRegistry.abi";
import { OwnedDelegateUnstructuredProxy } from "./commons-management/OwnedDelegateUnstructuredProxy.abi";
import { DefaultEcosystemRegistry } from "./commons-auth/DefaultEcosystemRegistry.abi";
import { EcosystemRegistryDb } from "./commons-auth/EcosystemRegistryDb.abi";
import { UpgradeOwned } from "./commons-management/UpgradeOwned.abi";
import { DefaultParticipantsManager } from "./commons-auth/DefaultParticipantsManager.abi";
import { ParticipantsManagerDb } from "./commons-auth/ParticipantsManagerDb.abi";
import { DefaultOrganization } from "./commons-auth/DefaultOrganization.abi";
import { DefaultUserAccount } from "./commons-auth/DefaultUserAccount.abi";
import { DefaultEcosystem } from "./commons-auth/DefaultEcosystem.abi";
import { DefaultProcessModelRepository } from "./bpm-model/DefaultProcessModelRepository.abi";
import { ProcessModelRepositoryDb } from "./bpm-model/ProcessModelRepositoryDb.abi";
import { DefaultApplicationRegistry } from "./bpm-runtime/DefaultApplicationRegistry.abi";
import { ApplicationRegistryDb } from "./bpm-runtime/ApplicationRegistryDb.abi";
import { DefaultBpmService } from "./bpm-runtime/DefaultBpmService.abi";
import { BpmServiceDb } from "./bpm-runtime/BpmServiceDb.abi";
import { DefaultProcessModel } from "./bpm-model/DefaultProcessModel.abi";
import { DefaultProcessDefinition } from "./bpm-model/DefaultProcessDefinition.abi";
import { DefaultProcessInstance } from "./bpm-runtime/DefaultProcessInstance.abi";
import { DefaultArchetypeRegistry } from "./agreements/DefaultArchetypeRegistry.abi";
import { ArchetypeRegistryDb } from "./agreements/ArchetypeRegistryDb.abi";
import { DefaultActiveAgreementRegistry } from "./agreements/DefaultActiveAgreementRegistry.abi";
import { ActiveAgreementRegistryDb } from "./agreements/ActiveAgreementRegistryDb.abi";
import { DefaultArchetype } from "./agreements/DefaultArchetype.abi";
import { DefaultActiveAgreement } from "./agreements/DefaultActiveAgreement.abi";
import { IsoCountries100 } from "./commons-standards/IsoCountries100.abi";
import { IsoCurrencies100 } from "./commons-standards/IsoCurrencies100.abi";
import { AgreementSignatureCheck } from "./agreements/AgreementSignatureCheck.abi";
import { RenewalWindowManager } from "./agreements/RenewalWindowManager.abi";
import { RenewalInitializer } from "./agreements/RenewalInitializer.abi";
import { RenewalEvaluator } from "./agreements/RenewalEvaluator.abi";
import { ApplicationRegistry } from "./bpm-runtime/ApplicationRegistry.abi";
import { TotalCounterCheck } from "./active-agreements/TotalCounterCheck.abi";
import { SetToNameRegistry } from "./lib/utils";
import { Contracts, Libraries } from "./lib/constants";
import { CallTx } from "@hyperledger/burrow/proto/payload_pb";
import { DeployDeadline, DeployWait } from "./bpm-oracles/deploy";
import { DeployNumbers } from "./commons-math/deploy";
import { Completables } from "./agreements/Completables.abi";
import { AgreementDates } from "./agreements/AgreementDates.abi";
import { AgreementRequestResponse } from "./agreements/AgreementRequestResponse.abi";

function assert(left: string, right: string) {
  if (left != right) throw new Error(`Expected to match: ${left} != ${right}`);
}

export async function DeployDOUG(
  client: Client,
  errorsLib: Promise<string>,
  eRC165Utils: Promise<string>
) {
  const errorsLibAddress = await errorsLib;
  const eRC165UtilsAddress = await eRC165Utils;

  const defaultArtifactsRegistryAddress = await DefaultArtifactsRegistry.Deploy(
    client,
    errorsLibAddress
  );
  const artifactsRegistryAddress = await OwnedDelegateUnstructuredProxy.Deploy(
    client,
    errorsLibAddress,
    defaultArtifactsRegistryAddress
  );
  const defaultArtifactsRegistry = new DefaultArtifactsRegistry.Contract(
    client,
    artifactsRegistryAddress
  );
  await defaultArtifactsRegistry.initialize();

  const defaultDougAddress = await DefaultDoug.Deploy(
    client,
    errorsLibAddress,
    eRC165UtilsAddress
  );
  const dougProxyAddress = await DougProxy.Deploy(
    client,
    errorsLibAddress,
    defaultDougAddress
  );
  const defaultDoug = new DefaultDoug.Contract(client, dougProxyAddress);

  await defaultArtifactsRegistry.transferSystemOwnership(dougProxyAddress);
  await defaultDoug.setArtifactsRegistry(artifactsRegistryAddress);

  const getArtifactsRegistryFromProxy = await defaultDoug
    .getArtifactsRegistry()
    .then((data) => data[0]);
  assert(artifactsRegistryAddress, getArtifactsRegistryFromProxy);

  return new DOUG.Contract(client, dougProxyAddress);
}

export async function DeployEcosystemRegistry(
  client: Client,
  doug: DOUG.Contract<CallTx>,
  errorsLib: Promise<string>,
  mappingsLib: Promise<string>
) {
  const errorsLibAddress = await errorsLib;
  const mappingsLibAddress = await mappingsLib;

  const ecosystemRegistryAddress = await DefaultEcosystemRegistry.Deploy(
    client,
    errorsLibAddress
  );
  const ecosystemRegistry = new DefaultEcosystemRegistry.Contract(
    client,
    ecosystemRegistryAddress
  );
  const ecosystemRegistryDbAddress = await EcosystemRegistryDb.Deploy(
    client,
    errorsLibAddress,
    mappingsLibAddress
  );
  const ecosystemRegistryDb = new EcosystemRegistryDb.Contract(
    client,
    ecosystemRegistryDbAddress
  );

  await ecosystemRegistryDb.transferSystemOwnership(ecosystemRegistryAddress);
  await ecosystemRegistry.acceptDatabase(ecosystemRegistryDb.address);
  const upgradeEcosystemOwnership = new UpgradeOwned.Contract(
    client,
    ecosystemRegistry.address
  );
  await upgradeEcosystemOwnership.transferUpgradeOwnership(doug.address);
  await doug.deploy(Contracts.EcosystemRegistry, ecosystemRegistry.address);
  return ecosystemRegistry;
}

export async function DeployParticipantsManager(
  client: Client,
  doug: DOUG.Contract<CallTx>,
  errorsLib: Promise<string>,
  mappingsLib: Promise<string>
) {
  const errorsLibAddress = await errorsLib;
  const mappingsLibAddress = await mappingsLib;

  const participantsManagerAddress = await DefaultParticipantsManager.Deploy(
    client,
    errorsLibAddress
  );
  const participantsManager = new DefaultParticipantsManager.Contract(
    client,
    participantsManagerAddress
  );
  const participantsManagerDbAddress = await ParticipantsManagerDb.Deploy(
    client,
    errorsLibAddress,
    mappingsLibAddress
  );
  const participantsManagerDb = new ParticipantsManagerDb.Contract(
    client,
    participantsManagerDbAddress
  );

  await participantsManagerDb.transferSystemOwnership(
    participantsManager.address
  );
  await participantsManager.acceptDatabase(participantsManagerDb.address);
  const upgradeParticipantsOwnership = new UpgradeOwned.Contract(
    client,
    participantsManager.address
  );
  await upgradeParticipantsOwnership.transferUpgradeOwnership(doug.address);
  await doug.deploy(Contracts.ParticipantsManager, participantsManager.address);
  return participantsManager;
}

export async function RegisterEcosystemAndParticipantClasses(
  client: Client,
  doug: DOUG.Contract<CallTx>,
  participantsManager: Promise<DefaultParticipantsManager.Contract<CallTx>>,
  ecosystemRegistry: Promise<DefaultEcosystemRegistry.Contract<CallTx>>,
  errorsLib: Promise<string>,
  mappingsLib: Promise<string>,
  arrayUtilsLib: Promise<string>
) {
  const errorsLibAddress = await errorsLib;
  const mappingsLibAddress = await mappingsLib;
  const arrayUtilsLibAddress = await arrayUtilsLib;

  const participants = await participantsManager;
  const ecosystem = await ecosystemRegistry;

  const defaultOrganizationAddress = await DefaultOrganization.Deploy(
    client,
    errorsLibAddress,
    mappingsLibAddress,
    arrayUtilsLibAddress
  );
  const objectClassOrganization = await participants
    .OBJECT_CLASS_ORGANIZATION()
    .then((data) => data[0]);
  await doug.register(objectClassOrganization, defaultOrganizationAddress);
  const defaultUserAccountAddress = await DefaultUserAccount.Deploy(
    client,
    errorsLibAddress,
    mappingsLibAddress
  );
  const objectClassUserAccount = await participants
    .OBJECT_CLASS_USER_ACCOUNT()
    .then((data) => data[0]);
  await doug.register(objectClassUserAccount, defaultUserAccountAddress);
  const defaultEcosystemAddress = await DefaultEcosystem.Deploy(
    client,
    errorsLibAddress,
    mappingsLibAddress
  );
  const objectClassEcosystem = await ecosystem
    .OBJECT_CLASS_ECOSYSTEM()
    .then((data) => data[0]);
  await doug.register(objectClassEcosystem, defaultEcosystemAddress);
}

export async function DeployProcessModelRepository(
  client: Client,
  doug: DOUG.Contract<CallTx>,
  errorsLib: Promise<string>,
  mappingsLib: Promise<string>,
  arrayUtilsLib: Promise<string>
) {
  const errorsLibAddress = await errorsLib;
  const mappingsLibAddress = await mappingsLib;
  const arrayUtilsLibAddress = await arrayUtilsLib;

  const processModelRepositoryAddress = await DefaultProcessModelRepository.Deploy(
    client,
    errorsLibAddress
  );
  const processModelRepository = new DefaultProcessModelRepository.Contract(
    client,
    processModelRepositoryAddress
  );
  const processModelRepositoryDbAddress = await ProcessModelRepositoryDb.Deploy(
    client,
    errorsLibAddress,
    mappingsLibAddress,
    arrayUtilsLibAddress
  );
  const processModelRepositoryDb = new ProcessModelRepositoryDb.Contract(
    client,
    processModelRepositoryDbAddress
  );

  await processModelRepositoryDb.transferSystemOwnership(
    processModelRepository.address
  );
  await processModelRepository.acceptDatabase(processModelRepositoryDb.address);
  const upgradeProcessModelOwnership = new UpgradeOwned.Contract(
    client,
    processModelRepository.address
  );
  await upgradeProcessModelOwnership.transferUpgradeOwnership(doug.address);
  await doug.deploy(
    Contracts.ProcessModelRepository,
    processModelRepository.address
  );
  return processModelRepository;
}

export async function DeployApplicationRegistry(
  client: Client,
  doug: DOUG.Contract<CallTx>,
  errorsLib: Promise<string>
) {
  const errorsLibAddress = await errorsLib;

  const applicationRegistryAddress = await DefaultApplicationRegistry.Deploy(
    client,
    errorsLibAddress
  );
  const applicationRegistry = new DefaultApplicationRegistry.Contract(
    client,
    applicationRegistryAddress
  );
  const applicationRegistryDbAddress = await ApplicationRegistryDb.Deploy(
    client,
    errorsLibAddress
  );
  const applicationRegistryDb = new ApplicationRegistryDb.Contract(
    client,
    applicationRegistryDbAddress
  );

  await applicationRegistryDb.transferSystemOwnership(
    applicationRegistry.address
  );
  await applicationRegistry.acceptDatabase(applicationRegistryDb.address);
  const upgradeApplicationRegistryOwnership = new UpgradeOwned.Contract(
    client,
    applicationRegistry.address
  );
  await upgradeApplicationRegistryOwnership.transferUpgradeOwnership(
    doug.address
  );
  await doug.deploy(Contracts.ApplicationRegistry, applicationRegistry.address);
  return applicationRegistry;
}

export async function DeployBpmService(
  client: Client,
  doug: DOUG.Contract<CallTx>,
  errorsLib: Promise<string>,
  mappingsLib: Promise<string>
) {
  const errorsLibAddress = await errorsLib;
  const mappingsLibAddress = await mappingsLib;

  const bpmServiceAddress = await DefaultBpmService.Deploy(
    client,
    errorsLibAddress,
    Contracts.ProcessModelRepository,
    Contracts.ApplicationRegistry
  );
  const bpmService = new DefaultBpmService.Contract(client, bpmServiceAddress);
  const bpmServiceDbAddress = await BpmServiceDb.Deploy(
    client,
    errorsLibAddress,
    mappingsLibAddress
  );
  const bpmServiceDb = new BpmServiceDb.Contract(client, bpmServiceDbAddress);

  await bpmServiceDb.transferSystemOwnership(bpmService.address);
  await bpmService.acceptDatabase(bpmServiceDb.address);
  const upgradeBpmServiceOwnership = new UpgradeOwned.Contract(
    client,
    bpmService.address
  );
  await upgradeBpmServiceOwnership.transferUpgradeOwnership(doug.address);
  await doug.deploy(Contracts.BpmService, bpmService.address);
  return bpmService;
}

export async function RegisterProcessModelRepositoryClasses(
  client: Client,
  doug: DOUG.Contract<CallTx>,
  contract: Promise<DefaultProcessModelRepository.Contract<CallTx>>,
  service: Promise<DefaultBpmService.Contract<CallTx>>,
  errorsLib: Promise<string>,
  mappingsLib: Promise<string>,
  arrayUtilsLib: Promise<string>,
  bpmModelLib: Promise<string>,
  typeUtilsLib: Promise<string>
) {
  const errorsLibAddress = await errorsLib;
  const mappingsLibAddress = await mappingsLib;
  const bpmModelLibAddress = await bpmModelLib;
  const arrayUtilsLibAddress = await arrayUtilsLib;
  const typeUtilsLibAddress = await typeUtilsLib;

  const processModelRepository = await contract;
  const bpmService = await service;

  const getModelRepositoryFromBpmService = await bpmService
    .getProcessModelRepository()
    .then((data) => data[0]);
  assert(getModelRepositoryFromBpmService, processModelRepository.address);

  const defaultProcessModelImplementationAddress = await DefaultProcessModel.Deploy(
    client,
    errorsLibAddress,
    mappingsLibAddress
  );
  const objectClassProcessModel = await processModelRepository
    .OBJECT_CLASS_PROCESS_MODEL()
    .then((data) => data[0]);
  await doug.register(
    objectClassProcessModel,
    defaultProcessModelImplementationAddress
  );

  const defaultProcessDefinitionImplementationAddress = await DefaultProcessDefinition.Deploy(
    client,
    bpmModelLibAddress,
    errorsLibAddress,
    arrayUtilsLibAddress,
    typeUtilsLibAddress
  );
  const objectClassProcessDefinition = await processModelRepository
    .OBJECT_CLASS_PROCESS_DEFINITION()
    .then((data) => data[0]);
  await doug.register(
    objectClassProcessDefinition,
    defaultProcessDefinitionImplementationAddress
  );
}

export async function RegisterApplicationRepositoryClasses(
  client: Client,
  doug: DOUG.Contract<CallTx>,
  contract: Promise<DefaultApplicationRegistry.Contract<CallTx>>,
  service: Promise<DefaultBpmService.Contract<CallTx>>,
  errorsLib: Promise<string>,
  bpmRuntimeLib: Promise<string>,
  dataStorageUtils: Promise<string>
) {
  const applicationRegistry = await contract;
  const bpmService = await service;

  const errorsLibAddress = await errorsLib;
  const bpmRuntimeLibAddress = await bpmRuntimeLib;
  const dataStorageUtilsAddress = await dataStorageUtils;

  const getApplicationRegistryFromBpmService = await bpmService
    .getApplicationRegistry()
    .then((data) => data[0]);
  assert(getApplicationRegistryFromBpmService, applicationRegistry.address);

  const defaultProcessInstanceImplementationAddress = await DefaultProcessInstance.Deploy(
    client,
    bpmRuntimeLibAddress,
    errorsLibAddress,
    dataStorageUtilsAddress
  );
  const objectClassProcessInstance = await bpmService
    .OBJECT_CLASS_PROCESS_INSTANCE()
    .then((data) => data[0]);
  await doug.register(
    objectClassProcessInstance,
    defaultProcessInstanceImplementationAddress
  );
}

export async function DeployArchetypeRegistry(
  client: Client,
  doug: DOUG.Contract<CallTx>,
  errorsLib: Promise<string>,
  mappingsLib: Promise<string>,
  arrayUtilsLib: Promise<string>
) {
  const errorsLibAddress = await errorsLib;
  const mappingsLibAddress = await mappingsLib;
  const arrayUtilsLibAddress = await arrayUtilsLib;

  const archetypeRegistryAddress = await DefaultArchetypeRegistry.Deploy(
    client,
    errorsLibAddress
  );
  const archetypeRegistry = new DefaultArchetypeRegistry.Contract(
    client,
    archetypeRegistryAddress
  );
  const archetypeRegistryDbAddress = await ArchetypeRegistryDb.Deploy(
    client,
    errorsLibAddress,
    mappingsLibAddress,
    arrayUtilsLibAddress
  );
  const archetypeRegistryDb = new ArchetypeRegistryDb.Contract(
    client,
    archetypeRegistryDbAddress
  );

  await archetypeRegistryDb.transferSystemOwnership(archetypeRegistry.address);
  await archetypeRegistry.acceptDatabase(archetypeRegistryDb.address);
  const upgradeArchetypeRegistryOwnership = new UpgradeOwned.Contract(
    client,
    archetypeRegistry.address
  );
  await upgradeArchetypeRegistryOwnership.transferUpgradeOwnership(
    doug.address
  );
  await doug.deploy(Contracts.ArchetypeRegistry, archetypeRegistry.address);
  return archetypeRegistry;
}

export async function DeployActiveAgreementRegistry(
  client: Client,
  doug: DOUG.Contract<CallTx>,
  errorsLib: Promise<string>,
  dataStorageUtils: Promise<string>,
  mappingsLib: Promise<string>,
  arrayUtilsLib: Promise<string>
) {
  const errorsLibAddress = await errorsLib;
  const dataStorageUtilsAddress = await dataStorageUtils;
  const mappingsLibAddress = await mappingsLib;
  const arrayUtilsLibAddress = await arrayUtilsLib;

  const activeAgreementRegistryAddress = await DefaultActiveAgreementRegistry.Deploy(
    client,
    errorsLibAddress,
    dataStorageUtilsAddress,
    Contracts.ArchetypeRegistry,
    Contracts.BpmService
  );
  const activeAgreementRegistry = new DefaultActiveAgreementRegistry.Contract(
    client,
    activeAgreementRegistryAddress
  );
  const activeAgreementRegistryDbAddress = await ActiveAgreementRegistryDb.Deploy(
    client,
    errorsLibAddress,
    mappingsLibAddress,
    arrayUtilsLibAddress
  );
  const activeAgreementRegistryDb = new ActiveAgreementRegistryDb.Contract(
    client,
    activeAgreementRegistryDbAddress
  );

  await activeAgreementRegistryDb.transferSystemOwnership(
    activeAgreementRegistry.address
  );
  await activeAgreementRegistry.acceptDatabase(
    activeAgreementRegistryDb.address
  );
  const upgradeActiveAgreementRegistryOwnership = new UpgradeOwned.Contract(
    client,
    activeAgreementRegistry.address
  );
  await upgradeActiveAgreementRegistryOwnership.transferUpgradeOwnership(
    doug.address
  );
  await doug.deploy(
    Contracts.ActiveAgreementRegistry,
    activeAgreementRegistry.address
  );
  return activeAgreementRegistry;
}

export async function RegisterAgreementClasses(
  client: Client,
  doug: DOUG.Contract<CallTx>,
  agreement: Promise<DefaultActiveAgreementRegistry.Contract<CallTx>>,
  archetype: Promise<DefaultArchetypeRegistry.Contract<CallTx>>,
  service: Promise<DefaultBpmService.Contract<CallTx>>,
  errorsLib: Promise<string>,
  mappingsLib: Promise<string>,
  eRC165Utils: Promise<string>,
  arrayUtilsLib: Promise<string>,
  agreementsAPI: Promise<string>,
  dataStorageUtils: Promise<string>
) {
  const activeAgreementRegistry = await agreement;
  const archetypeRegistry = await archetype;
  const bpmService = await service;

  const errorsLibAddress = await errorsLib;
  const mappingsLibAddress = await mappingsLib;
  const eRC165UtilsAddress = await eRC165Utils;
  const arrayUtilsLibAddress = await arrayUtilsLib;
  const agreementsAPIAddress = await agreementsAPI;
  const dataStorageUtilsAddress = await dataStorageUtils;

  const getBpmServiceFromAgreementRegistry = await activeAgreementRegistry
    .getBpmService()
    .then((data) => data.location);
  assert(getBpmServiceFromAgreementRegistry, bpmService.address);
  const getArchetypeRegistryFromAgreementRegistry = await activeAgreementRegistry
    .getArchetypeRegistry()
    .then((data) => data.location);
  assert(getArchetypeRegistryFromAgreementRegistry, archetypeRegistry.address);

  const defaultArchetypeImplementationAddress = await DefaultArchetype.Deploy(
    client,
    errorsLibAddress,
    mappingsLibAddress,
    eRC165UtilsAddress,
    arrayUtilsLibAddress
  );
  const objectClassArchetype = await archetypeRegistry
    .OBJECT_CLASS_ARCHETYPE()
    .then((data) => data[0]);
  await doug.register(
    objectClassArchetype,
    defaultArchetypeImplementationAddress
  );
  const defaultActiveAgreementImplementationAddress = await DefaultActiveAgreement.Deploy(
    client,
    agreementsAPIAddress,
    errorsLibAddress,
    dataStorageUtilsAddress,
    mappingsLibAddress,
    eRC165UtilsAddress,
    arrayUtilsLibAddress
  );
  const objectClassActiveAgreement = await activeAgreementRegistry
    .OBJECT_CLASS_AGREEMENT()
    .then((data) => data[0]);
  await doug.register(
    objectClassActiveAgreement,
    defaultActiveAgreementImplementationAddress
  );
}

export async function DeployLib(
  cli: Client,
  call: (client: Client, ...arg1: string[]) => Promise<string>,
  ...addr: Promise<string>[]
): Promise<string> {
  const addresses = await Promise.all(addr);
  return call(cli, ...addresses);
}

export async function RegisterLib(
  doug: DOUG.Contract<CallTx>,
  id: string,
  lib: Promise<string>
) {
  const address = await lib;
  await doug.register(id, address);
}

export async function DeployRenewalWindowManager(
  client: Client,
  doug: DOUG.Contract<CallTx>,
  service: Promise<DefaultBpmService.Contract<CallTx>>,
  registry: Promise<DefaultApplicationRegistry.Contract<CallTx>>,
  errorsLib: Promise<string>
) {
  const bpmService = await service;
  const errorsLibAddress = await errorsLib;
  const renewalWindowManagerAddress = await RenewalWindowManager.Deploy(
    client,
    errorsLibAddress,
    bpmService.address
  );
  const applicationRegistry = await registry;
  await Promise.all([
    applicationRegistry.addApplication(
      Buffer.from("RenewalWindowManager"),
      0,
      renewalWindowManagerAddress,
      Buffer.from(""),
      Buffer.from("")
    ),
    doug.deploy("RenewalWindowManager", renewalWindowManagerAddress),
  ]);
}

export async function DeployCompletables(
  client: Client,
  doug: DOUG.Contract<CallTx>,
  agreementsApi: Promise<string>,
  errorsLib: Promise<string>,
  stringsLib: Promise<string>
) {
  const completables = await DeployLib(
    client,
    Completables.Deploy,
    agreementsApi,
    errorsLib,
    stringsLib
  );
  await new UpgradeOwned.Contract(
    client,
    completables
  ).transferUpgradeOwnership(doug.address);
  await doug.deploy(Contracts.Completables, completables);
}

export async function DeployAgreementDates(
  client: Client,
  doug: DOUG.Contract<CallTx>,
  agreementsApi: Promise<string>,
  errorsLib: Promise<string>,
  stringsLib: Promise<string>
) {
  const agreementDates = await DeployLib(
    client,
    AgreementDates.Deploy,
    agreementsApi,
    errorsLib,
    stringsLib
  );
  await new UpgradeOwned.Contract(
    client,
    agreementDates
  ).transferUpgradeOwnership(doug.address);
  await doug.deploy(Contracts.AgreementDates, agreementDates);
}

export async function DeployAgreementRequestResponse(
  client: Client,
  doug: DOUG.Contract<CallTx>
) {
  const agreementRequestResponse = await DeployLib(
    client,
    AgreementRequestResponse.Deploy
  );
  await new UpgradeOwned.Contract(
    client,
    agreementRequestResponse
  ).transferUpgradeOwnership(doug.address);
  await doug.deploy(
    Contracts.AgreementRequestResponse,
    agreementRequestResponse
  );
}

export async function DeployRenewalInitializer(
  client: Client,
  doug: DOUG.Contract<CallTx>,
  registry: Promise<DefaultApplicationRegistry.Contract<CallTx>>,
  errorsLib: Promise<string>
) {
  const errorsLibAddress = await errorsLib;
  const renewalInitializer = await RenewalInitializer.Deploy(
    client,
    errorsLibAddress
  );
  const applicationRegistry = await registry;
  await Promise.all([
    applicationRegistry.addApplication(
      Buffer.from("RenewalInitializer"),
      0,
      renewalInitializer,
      Buffer.from(""),
      Buffer.from("")
    ),
    doug.deploy("RenewalInitializer", renewalInitializer),
  ]);
}

export async function DeployRenewalEvaluator(
  client: Client,
  doug: DOUG.Contract<CallTx>,
  registry: Promise<DefaultApplicationRegistry.Contract<CallTx>>
) {
  const renewalEvaluator = await RenewalEvaluator.Deploy(client);
  const applicationRegistry = await registry;
  await Promise.all([
    applicationRegistry.addApplication(
      Buffer.from("RenewalEvaluator"),
      0,
      renewalEvaluator,
      Buffer.from(""),
      Buffer.from("")
    ),
    doug.deploy("RenewalEvaluator", renewalEvaluator),
  ]);
}

export async function Deploy(client: Client) {
  const errorsLib = ErrorsLib.Deploy(client);
  const typeUtilsLib = TypeUtilsLib.Deploy(client);
  const arrayUtilsLib = ArrayUtilsLib.Deploy(client);
  const mappingsLib = DeployLib(
    client,
    MappingsLib.Deploy,
    arrayUtilsLib,
    typeUtilsLib
  );
  const stringsLib = Strings.Deploy(client);
  const dataStorageUtils = DeployLib(
    client,
    DataStorageUtils.Deploy,
    errorsLib,
    typeUtilsLib
  );
  const eRC165Utils = ERC165Utils.Deploy(client);
  const bpmModelLib = DeployLib(
    client,
    BpmModelLib.Deploy,
    errorsLib,
    dataStorageUtils
  );
  const bpmRuntimeLib = DeployLib(
    client,
    BpmRuntimeLib.Deploy,
    errorsLib,
    dataStorageUtils,
    eRC165Utils,
    typeUtilsLib
  );
  const agreementsAPI = DeployLib(client, AgreementsAPI.Deploy, eRC165Utils);
  const dataTypesAccess = DataTypesAccess.Deploy(client);

  const doug = await DeployDOUG(client, errorsLib, eRC165Utils);
  const ecosystemRegistry = DeployEcosystemRegistry(
    client,
    doug,
    errorsLib,
    mappingsLib
  );
  const participantsManager = DeployParticipantsManager(
    client,
    doug,
    errorsLib,
    mappingsLib
  );
  const processModelRepository = DeployProcessModelRepository(
    client,
    doug,
    errorsLib,
    mappingsLib,
    arrayUtilsLib
  );
  const applicationRegistry = DeployApplicationRegistry(
    client,
    doug,
    errorsLib
  );
  const bpmService = DeployBpmService(client, doug, errorsLib, mappingsLib);
  const archetypeRegistry = DeployArchetypeRegistry(
    client,
    doug,
    errorsLib,
    mappingsLib,
    arrayUtilsLib
  );
  const activeAgreementRegistry = DeployActiveAgreementRegistry(
    client,
    doug,
    errorsLib,
    dataStorageUtils,
    mappingsLib,
    arrayUtilsLib
  );
  await Promise.all([
    SetToNameRegistry(client, Contracts.DOUG, doug.address),
    RegisterEcosystemAndParticipantClasses(
      client,
      doug,
      participantsManager,
      ecosystemRegistry,
      errorsLib,
      mappingsLib,
      arrayUtilsLib
    ),
    RegisterProcessModelRepositoryClasses(
      client,
      doug,
      processModelRepository,
      bpmService,
      errorsLib,
      mappingsLib,
      arrayUtilsLib,
      bpmModelLib,
      typeUtilsLib
    ),
    RegisterApplicationRepositoryClasses(
      client,
      doug,
      applicationRegistry,
      bpmService,
      errorsLib,
      bpmRuntimeLib,
      dataStorageUtils
    ),
    RegisterAgreementClasses(
      client,
      doug,
      activeAgreementRegistry,
      archetypeRegistry,
      bpmService,
      errorsLib,
      mappingsLib,
      eRC165Utils,
      arrayUtilsLib,
      agreementsAPI,
      dataStorageUtils
    ),
    DeployLib(client, IsoCountries100.Deploy, errorsLib),
    DeployLib(client, IsoCurrencies100.Deploy, errorsLib),
  ]);

  // Applications
  // ApplicationTypes Enum: {0=EVENT, 1=SERVICE, 2=WEB}

  const appRegistry = new ApplicationRegistry.Contract(
    client,
    (await applicationRegistry).address
  );
  const agreementSignatureCheckAddress = await AgreementSignatureCheck.Deploy(
    client
  );
  const totalCounterCheckAddress = await TotalCounterCheck.Deploy(client);

  await Promise.all([
    appRegistry.addApplication(
      Buffer.from("AgreementSignatureCheck"),
      2,
      agreementSignatureCheckAddress,
      Buffer.from(""),
      Buffer.from("SigningWebFormWithSignatureCheck")
    ),
    appRegistry.addAccessPoint(
      Buffer.from("AgreementSignatureCheck"),
      Buffer.from("agreement"),
      59,
      0
    ),
    appRegistry.addApplication(
      Buffer.from("TotalCounterCheck"),
      1,
      totalCounterCheckAddress,
      Buffer.from(""),
      Buffer.from("")
    ),
    appRegistry.addAccessPoint(
      Buffer.from("TotalCounterCheck"),
      Buffer.from("numberIn"),
      8,
      0
    ),
    appRegistry.addAccessPoint(
      Buffer.from("TotalCounterCheck"),
      Buffer.from("totalIn"),
      8,
      0
    ),
    appRegistry.addAccessPoint(
      Buffer.from("TotalCounterCheck"),
      Buffer.from("numberOut"),
      8,
      1
    ),
    appRegistry.addAccessPoint(
      Buffer.from("TotalCounterCheck"),
      Buffer.from("completedOut"),
      1,
      1
    ),
  ]);

  await Promise.all([
    DeployRenewalWindowManager(
      client,
      doug,
      bpmService,
      applicationRegistry,
      errorsLib
    ),
    DeployRenewalInitializer(client, doug, applicationRegistry, errorsLib),
    DeployRenewalEvaluator(client, doug, applicationRegistry),
    DeployDeadline(client, doug, bpmService, applicationRegistry, errorsLib),
    DeployWait(client, doug, bpmService, applicationRegistry, errorsLib),
    DeployNumbers(client, applicationRegistry),
    DeployCompletables(client, doug, agreementsAPI, errorsLib, stringsLib),
    DeployAgreementDates(client, doug, agreementsAPI, errorsLib, stringsLib),
    DeployAgreementRequestResponse(client, doug),
  ]);

  await Promise.all([
    RegisterLib(doug, Libraries.ErrorsLib, errorsLib),
    RegisterLib(doug, Libraries.TypeUtilsLib, typeUtilsLib),
    RegisterLib(doug, Libraries.ArrayUtilsLib, arrayUtilsLib),
    RegisterLib(doug, Libraries.MappingsLib, mappingsLib),
    RegisterLib(doug, Libraries.DataStorageUtils, dataStorageUtils),
    RegisterLib(doug, Libraries.ERC165Utils, eRC165Utils),
    RegisterLib(doug, Libraries.BpmModelLib, bpmModelLib),
    RegisterLib(doug, Libraries.BpmRuntimeLib, bpmRuntimeLib),
    RegisterLib(doug, Libraries.AgreementsAPI, agreementsAPI),
    RegisterLib(doug, Libraries.Strings, stringsLib),
  ]);
}
