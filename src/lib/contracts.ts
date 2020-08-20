import {Client} from './client';
import {Manager, NewManager} from './manager';
import {
  BytesFromString,
  BytesToString,
  CallOnBehalfOf,
  DecodeHex,
  GetFromNameRegistry,
  SetToNameRegistry
} from './utils';
import {ActiveAgreement} from '../agreements/ActiveAgreement.abi';
import {Archetype} from '../agreements/Archetype.abi';
import {RenewalWindowManager} from '../agreements/RenewalWindowManager.abi';
import {ProcessModel} from '../bpm-model/ProcessModel.abi';
import {ProcessDefinition} from '../bpm-model/ProcessDefinition.abi';
import {ProcessInstance} from '../bpm-runtime/ProcessInstance.abi';
import {Direction, ErrorCode} from './constants';
import {CallTx} from '@hyperledger/burrow/proto/payload_pb';
import {Ecosystem_v1_0_1 as Ecosystem} from '../commons-auth/Ecosystem_v1_0_1.abi';
import {Organization} from '../commons-auth/Organization.abi';
import {Agreement as agreement, Archetype as archetype, DataType, Parameter,} from './types';
import {getLogger, Logger} from 'log4js';
import {VentListener, BurrowWatcher} from "./vent";

export async function RegisterEcosystem(client: Client, manager: Manager, account: string, name: string) {
    const address = await manager.EcosystemRegistry
        .createEcosystem(name)
        .then(data => data[0]);
    await new Ecosystem.Contract(client, address).addExternalAddress(account);
    await SetToNameRegistry(client, name, address);
    return address;
}

export class Contracts {
    client: Client;
    manager: Manager;
    account: string;
    ecosystem: string;
    log: Logger;

    constructor(client: Client, manager: Manager, ecosystem: string) {
        this.client = client;
        this.account = client.account;
        this.manager = manager;
        this.ecosystem = ecosystem;
        this.log = getLogger('contracts');
        this.log.level = 'debug';
    }

    async getFromNameRegistry(name: string) {
        this.log.debug(`REQUEST: Get from name registry: ${name}`);
        return GetFromNameRegistry(this.client, name);
    }

    async setToNameRegistry(name: string, value: string) {
        this.log.debug(`REQUEST: Set to name registry: ${JSON.stringify({ name, value })}`);
        return SetToNameRegistry(this.client, name, value);
    }

    async callOnBehalfOf(userAddress: string, targetAddress: string, payload: string) {
        this.log.debug(`REQUEST: Call target ${targetAddress} on behalf of user ${userAddress} with payload: ${payload}`);
        const data = await CallOnBehalfOf(this.client, userAddress, targetAddress, payload);
        this.log.info(`SUCCESS: ReturnData from target ${targetAddress} forwardCall on behalf of user ${userAddress}: ${data}`);
        return data;
    }

    async createAgreement(agreement: agreement) {
        const {
            archetype,
            creator,
            owner,
            privateParametersFileReference,
            parties,
            collectionId,
            governingAgreements,
        } = agreement;
        const isPrivate = agreement.isPrivate || false;
        this.log.debug(`REQUEST: Create agreement with following data: ${JSON.stringify(agreement)}`);
        return this.manager.ActiveAgreementRegistry
            .createAgreement(archetype, creator, owner, privateParametersFileReference, isPrivate, parties, DecodeHex(collectionId), governingAgreements)
            .then(data => {
                this.log.info(`SUCCESS: Created agreement by ${creator} at address ${data.activeAgreement}`);
                return data.activeAgreement;
            });
    }

    async setLegalState(agreementAddress: string, legalState: number) {
        this.log.debug(`REQUEST: Set legal state of agreement ${agreementAddress} to ${legalState}`);
        const agreement = new ActiveAgreement.Contract(this.client, agreementAddress);
        const permissionId = await agreement.ROLE_ID_LEGAL_STATE_CONTROLLER().then(data => data[0]);
        const hasPermission = (await agreement.hasPermission(permissionId, this.account))[0];
        if (!hasPermission) await agreement.grantPermission(permissionId, this.account);
        await agreement.setLegalState(legalState);
        await agreement.revokePermission(permissionId, this.account);
    }

    async initializeObjectAdministrator(agreementAddress: string) {
        this.log.debug(`REQUEST: Initializing agreement admin role for agreement: ${agreementAddress}`);
        const agreement = new ActiveAgreement.Contract(this.client, agreementAddress);
        await agreement.initializeObjectAdministrator(this.account)
        this.log.info(`SUCCESS: Initialized agreement admin role for agreement ${agreementAddress}`);
    }

    async setMaxNumberOfAttachments(agreementAddress: string, maxNumberOfAttachments: number) {
        this.log.debug(`REQUEST: Set max number of events to ${maxNumberOfAttachments} for agreement at ${agreementAddress}`);
        const agreement = new ActiveAgreement.Contract(this.client, agreementAddress);
        await agreement.setMaxNumberOfEvents(maxNumberOfAttachments)
    }

    async setAddressScopeForAgreementParameters(agreementAddress: string, parameters: Array<{ name: string, value: string, scope: string }>) {
        this.log.debug(`REQUEST: Add scopes to agreement ${agreementAddress} parameters: ${JSON.stringify(parameters)}`);
        const agreement = new ActiveAgreement.Contract(this.client, agreementAddress);

        const promises = parameters.map(async ({ name, value, scope }) => {
            return agreement.setAddressScope(value, BytesFromString(name), DecodeHex(scope), BytesFromString(''), BytesFromString(''), '0x0')
        });
        await Promise.all(promises);
        this.log.info(`SUCCESS: Added scopes to agreement ${agreementAddress} parameters`);
    }

    async updateAgreementFileReference(fileKey: string, agreementAddress: string, hoardGrant: string) {
        this.log.debug(`REQUEST: Update reference for  ${fileKey} for agreement at ${agreementAddress} with new reference ${hoardGrant}`);
        const agreement = new ActiveAgreement.Contract(this.client, agreementAddress);
        switch (fileKey) {
            case 'EventLog':
                await agreement.setEventLogReference(hoardGrant);
                break;
            case 'SignatureLog':
                await agreement.setSignatureLogReference(hoardGrant);
                break;
            case 'PrivateParameters':
                await agreement.setPrivateParametersReference(hoardGrant);
                break;
        }
    }

    async defineRenewalTerms(
        agreementAddress: string,
        franchisees: string[],
        threshold: number,
        expirationDate: number,
        renewalOpenOffset: string,
        renewalCloseOffset: string,
        extensionOffset: string
    ): Promise<void> {
        this.log.debug(`REQUEST: Defining agreement renewal obligation  for agreement at ${agreementAddress} with data 
            ${JSON.stringify({
                franchisees,
                threshold,
                expirationDate,
                renewalOpenOffset,
                renewalCloseOffset,
                extensionOffset,
            })}`);
        const agreement = new ActiveAgreement.Contract(this.client, agreementAddress);
        await agreement.defineRenewalTerms(
            franchisees,
            threshold,
            expirationDate,
            renewalOpenOffset,
            renewalCloseOffset,
            extensionOffset
        );
    }

    async createAgreementCollection(author: string, collectionType: number, packageId: string) {
        this.log.debug(`REQUEST: Create agreement collection by ${author} with type ${collectionType} ` +
            `and packageId ${packageId} created by user at ${author}`);
        return this.manager.ActiveAgreementRegistry
            .createAgreementCollection(author, collectionType, DecodeHex(packageId))
            .then(data => {
                if (data.error !== 1) throw new Error(`Error code adding agreement collection by ${author}: ${data.error}`);
                this.log.info(`SUCCESS: Created new agreement collection by ${author} with id ${data.id}`);
                return data.id;
            });
    }

    async addAgreementToCollection(collectionId: string, agreement: string) {
        this.log.debug(`REQUEST: Add agreement at ${agreement} to collection ${collectionId}`);
        return this.manager.ActiveAgreementRegistry
            .addAgreementToCollection(DecodeHex(collectionId), agreement);
    }

    async signAgreement(actingUserAddress: string, agreementAddress: string) {
        this.log.debug(`REQUEST: Sign agreement ${agreementAddress} by user ${actingUserAddress}`);
        const payload = ActiveAgreement.Encode(this.client).sign()
        await this.callOnBehalfOf(actingUserAddress, agreementAddress, payload);
    }

    async castRenewalVote(actingUserAddress: string, agreementAddress: string, renew: boolean) {
        this.log.debug(`REQUEST: Cast agreement renewal vote by user ${actingUserAddress} for agreement ${agreementAddress}`);
        const payload = ActiveAgreement.Encode(this.client).castRenewalVote(renew);
        await this.callOnBehalfOf(actingUserAddress, agreementAddress, payload);
    }

    async isAgreementSignedBy(agreementAddress: string, userAddress: string) {
        this.log.debug(`REQUEST: Checking if agreement at ${agreementAddress} has been signed by user at ${userAddress}`);
        const payload = ActiveAgreement.Encode(this.client).isSignedBy(userAddress);
        const response = await this.callOnBehalfOf(userAddress, agreementAddress, payload);
        const data = ActiveAgreement.Decode(this.client, DecodeHex(response)).isSignedBy();
        const isSignedBy = data[0].valueOf();
        return isSignedBy;
    }

    async cancelAgreement(actingUserAddress: string, agreementAddress: string) {
        this.log.debug('REQUEST: Cancel agreement %s by user %s', agreementAddress, actingUserAddress);
        const payload = ActiveAgreement.Encode(this.client).cancel();
        return this.callOnBehalfOf(actingUserAddress, agreementAddress, payload);
    }

    async redactAgreement(actingUserAddress: string, agreementAddress: string) {
        this.log.debug('REQUEST: Redact agreement %s by user %s', agreementAddress, actingUserAddress);
        const payload = ActiveAgreement.Encode(this.client).redact();
        const data = await this.callOnBehalfOf(actingUserAddress, agreementAddress, payload);
        return ActiveAgreement.Decode(this.client, DecodeHex(data)).redact()[0];
    }

    async getActiveAgreementData(agreementAddress: string) {
        this.log.debug(`REQUEST: Get data for agreement at address ${agreementAddress}`);
        return this.manager.ActiveAgreementRegistry
            .getActiveAgreementData(agreementAddress);
    }

    getActiveAgreement(address: string) {
        return new ActiveAgreement.Contract(this.client, address);
    }

    getRenewalWindowManager(address: string) {
        return new RenewalWindowManager.Contract(this.client, address);
    }

    async startProcessFromAgreement(agreementAddress: string) {
        this.log.debug(`REQUEST: Start formation process from agreement at address: ${agreementAddress}`);
        return this.manager.ActiveAgreementRegistry
            .startProcessLifecycle(agreementAddress)
            .then(async data => {
                if (data.error !== 1) throw new Error(ErrorCode.RUNTIME_ERROR);
                this.log.info(`SUCCESS: Formation process for agreement at ${agreementAddress} created and started at address: ${data.processInstance}`);
                return data.processInstance;
            });
    }

    async createArchetype(archetype: archetype) {
        const {
            price,
            active,
            author,
            owner,
            formationProcess,
            executionProcess,
            packageId,
            governingArchetypes,
        } = archetype;
        const isPrivate = archetype.isPrivate || false;
        this.log.debug(`REQUEST: Create archetype with: ${JSON.stringify(archetype)}`);
        return this.manager.ArchetypeRegistry
            .createArchetype(price, isPrivate, active, author, owner, formationProcess, executionProcess, DecodeHex(packageId), governingArchetypes)
            .then(data => data.archetype);
    }

    async isActiveArchetype(archetypeAddress: string) {
        this.log.debug(`REQUEST: Determine if archetype at ${archetypeAddress} is active`);
        return new Archetype.Contract(this.client, archetypeAddress)
            .isActive()
            .then(data => {
                this.log.info(`SUCCESS: Archetype at ${archetypeAddress} has been found to be ${data[0] ? 'active' : 'inactive'}`);
                return data[0];
            });
    }

    async getArchetypeAuthor(archetypeAddress: string) {
        this.log.debug(`REQUEST: Get archetype author for archetype at ${archetypeAddress}`);
        return new Archetype.Contract(this.client, archetypeAddress)
            .getAuthor().then(value => value.author);
    }

    async activateArchetype(archetypeAddress: string, userAccount: string) {
        this.log.debug(`REQUEST: Activate archetype at ${archetypeAddress} by user at ${userAccount}`);
        const payload = Archetype.Encode(this.client).activate();
        await this.callOnBehalfOf(userAccount, archetypeAddress, payload);
        this.log.info(`SUCCESS: Archetype at ${archetypeAddress} activated by user at ${userAccount}`);
    }

    async deactivateArchetype(archetypeAddress: string, userAccount: string) {
        this.log.debug(`REQUEST: Deactivate archetype at ${archetypeAddress} by user at ${userAccount}`);
        const payload = Archetype.Encode(this.client).deactivate();
        await this.callOnBehalfOf(userAccount, archetypeAddress, payload);
        this.log.info(`SUCCESS: Archetype at ${archetypeAddress} deactivated by user at ${userAccount}`);
    }

    async setArchetypeSuccessor(archetypeAddress: string, successorAddress: string, userAccount: string) {
        this.log.debug(`REQUEST: Set successor to ${successorAddress} for archetype at ${archetypeAddress} by user at ${userAccount}`);
        const payload = Archetype.Encode(this.client).setSuccessor(successorAddress);
        await this.callOnBehalfOf(userAccount, archetypeAddress, payload);
    }

    async getArchetypeSuccessor(archetypeAddress: string) {
        this.log.debug(`REQUEST: Get successor for archetype at ${archetypeAddress}`);
        return this.manager.ArchetypeRegistry
            .getArchetypeSuccessor(archetypeAddress)
            .then(data => data[0]);
    }

    async addArchetypeParameters(address: string, parameters: Array<Parameter>) {
        const paramTypes: number[] = [];
        const paramNames: Buffer[] = [];
        for (let i = 0; i < parameters.length; i += 1) {
          paramTypes[i] = parameters[i].type;
          paramNames[i] = BytesFromString(parameters[i].name);
        }
        this.log.debug(`REQUEST: Add archetype parameters to archetype at address ${address}. ` +
            `Parameter Types: ${JSON.stringify(paramTypes)}, Parameter Names: ${JSON.stringify(parameters.map(item => item.name))}`);
        return this.manager.ArchetypeRegistry
            .addParameters(address, paramTypes, paramNames)
            .then(data => {
                if (data.error !== 1) throw new Error(`Error code adding parameter to archetype at ${address}: ${data.error}`);
                else this.log.info(`SUCCESS: Added parameters ${parameters.map(({ name }) => name)} to archetype at ${address}`);
            });
    }

    async addArchetypeDocument(address: string, fileReference: string) {
        this.log.debug(`REQUEST: Add document to archetype at ${address}`);
        return this.manager.ArchetypeRegistry
            .addDocument(address, fileReference);
    }

    async addArchetypeDocuments(archetypeAddress: string, documents: Array<{ grant: string, name: string }>) {
        const names = documents.map(doc => doc.name).join(', ');
        this.log.debug(`REQUEST: Add archetype documents to archetype at ${archetypeAddress}: ${names}`);
        const resolvedDocs = await Promise.all(documents.map(async ({ grant }) => {
          const result = await this.addArchetypeDocument(archetypeAddress, grant);
          return result;
        }));
        return resolvedDocs;
    }

    async setArchetypePrice(address: string, price: number) {
        this.log.debug(`REQUEST: Set price to ${price} for archetype at ${address}`);
        const priceInCents = Math.floor(price * 100); // monetary unit conversion to cents which is the recorded unit on chain
        return this.manager.ArchetypeRegistry
            .setArchetypePrice(address, priceInCents);
    }

    async upgradeOwnerPermission(address: string, owner: string) {
        return new Archetype.Contract(this.client, address)
            .upgradeOwnerPermission(owner);
    }

    async createArchetypePackage(author: string, isPrivate: boolean, active: boolean) {
        this.log.debug(`REQUEST: Create a ${(isPrivate ? 'private' : 'public')}, ${(active ? 'active' : 'inactive')} archetype package by user at ${author}`);
        return this.manager.ArchetypeRegistry
            .createArchetypePackage(author, isPrivate, active)
            .then(data => {
                if (data.error !== 1) throw new Error(ErrorCode.RUNTIME_ERROR);
                else return data.id;
            })
      }

    async activateArchetypePackage(packageId: string, userAccount: string) {
        this.log.debug(`REQUEST: Activate archetype package with id ${packageId} by user at ${userAccount}`);
        return this.manager.ArchetypeRegistry
            .activatePackage(DecodeHex(packageId), userAccount);
    }

    async deactivateArchetypePackage(packageId: string, userAccount: string) {
        this.log.debug(`REQUEST: Deactivate archetype package with id ${packageId} by user at ${userAccount}`);
        return this.manager.ArchetypeRegistry
            .deactivatePackage(DecodeHex(packageId), userAccount);
    }

    async addArchetypeToPackage(packageId: string, archetype: string) {
        this.log.debug(`REQUEST: Add archetype at ${archetype} to package ${packageId}`);
        return this.manager.ArchetypeRegistry
            .addArchetypeToPackage(DecodeHex(packageId), archetype);
    }

    async addJurisdictions(address: string, jurisdictions: Array<{ country: string, regions: Array<string>}>) {
        const countries: Buffer[] = [];
        const regions: Buffer[] = [];
        jurisdictions.forEach((item) => {
            if (item.regions.length > 0) {
                item.regions.forEach((region) => {
                    countries.push(BytesFromString(item.country));
                    regions.push(BytesFromString(region));
                });
            } else {
                countries.push(BytesFromString(item.country));
                regions.push(BytesFromString(''));
            }
        });

        this.log.debug(`REQUEST: Add jurisdictions to archetype at ${address}. ` +
            `Countries: ${JSON.stringify(countries)}, Regions: ${JSON.stringify(regions)}`);

        return this.manager.ArchetypeRegistry
            .addJurisdictions(address, countries, regions);
    }

    async getArchetypeProcesses(archAddress: string) {
        this.log.debug(`REQUEST: Get formation and execution processes for archetype at address ${archAddress}`);
        const data = await this.manager.ArchetypeRegistry.getArchetypeData(archAddress);
        const formation = data.formationProcessDefinition;
        const execution = data.executionProcessDefinition;
        this.log.info(`SUCCESS: Retrieved processes for archetype ${archAddress}. Formation: ${formation}, Execution: ${execution}}`);
        return {
            formation: formation,
            execution: execution,
        }
    }

    async createProcessModel(modelId: string, modelVersion: [number, number, number], author: string, isPrivate: boolean, modelFileReference: string) {
        this.log.debug(`REQUEST: Create process model with following data: ${JSON.stringify({
            modelId,
            modelVersion,
            author,
            isPrivate,
            modelFileReference,
        })}`);
        return this.manager.ProcessModelRepository
            .createProcessModel(BytesFromString(modelId), modelVersion, author, isPrivate, modelFileReference)
            .then(value => value.modelAddress);
    }

    async addDataDefinitionToModel(pmAddress: string, dataStoreField: { dataStorageId: string, dataPath: string, parameterType: number }) {
        this.log.debug(`REQUEST: Add data definition ${JSON.stringify(dataStoreField)} to process model ${pmAddress}`);
        await new ProcessModel.Contract(this.client, pmAddress)
            .addDataDefinition(BytesFromString(dataStoreField.dataStorageId), BytesFromString(dataStoreField.dataPath), dataStoreField.parameterType);
        this.log.info(`SUCCESS: Data definition ${JSON.stringify(dataStoreField)} added to Process Model at ${pmAddress}`);
        return dataStoreField;
    }

    async addProcessInterface(pmAddress: string, interfaceId: string) {
        this.log.debug(`REQUEST: Add process interface ${interfaceId} to process model at ${pmAddress}`);
        return new ProcessModel.Contract(this.client, pmAddress)
            .addProcessInterface(BytesFromString(interfaceId))
            .then(data => {
                // interfaceId already registered to model
                if (data.error === 1002) return;
                else if (data.error !== 1) throw new Error(`Error code while adding process interface ${interfaceId} to model at ${pmAddress}: ${data[0]}`);
                this.log.info(`SUCCESS: Interface ${interfaceId} added to Process Model at ${pmAddress}`);
            });
    }

    async addParticipant(pmAddress: string, participantId: string, accountAddress: string, dataPath: string, dataStorageId: string, dataStorageAddress: string) {
        this.log.debug(`REQUEST: Add participant ${participantId} to process model at ${pmAddress} with data: ${JSON.stringify({
            accountAddress,
            dataPath,
            dataStorageId,
            dataStorageAddress,
        })}`);
        await new ProcessModel.Contract(this.client, pmAddress)
            .addParticipant(BytesFromString(participantId), accountAddress, BytesFromString(dataPath), BytesFromString(dataStorageId), dataStorageAddress)
            .then(data => {
                if (data.error !== 1) throw new Error(`Error code while adding participant ${participantId} to model ${pmAddress}: ${data[0]}`);
                this.log.info(`SUCCESS: Participant ${participantId} added to model ${pmAddress}`);
            })
    }

    async createProcessDefinition(modelAddress: string, processDefnId: string) {
        this.log.debug(`REQUEST: Create process definition with Id ${processDefnId} for process model ${modelAddress}`);
        return this.manager.ProcessModelRepository
                .createProcessDefinition(modelAddress, BytesFromString(processDefnId))
                .then(value => value.newAddress);
    }

    async addProcessInterfaceImplementation(pmAddress: string, pdAddress: string, interfaceId: string) {
        this.log.debug(`REQUEST: Add process interface implementation ${interfaceId} to process definition ${pdAddress} for process model ${pmAddress}`);
        await new ProcessDefinition.Contract(this.client, pdAddress)
            .addProcessInterfaceImplementation(pmAddress, BytesFromString(interfaceId))
            .then(data => {
                if (data.error === 1001) throw new Error(`InterfaceId ${interfaceId} for process at ${pdAddress} is not registered to the model at ${pmAddress}`);
                else if (data.error !== 1) throw new Error(`Error code while adding process interface implementation ${interfaceId} to process at ${pdAddress}: ${data[0]}`);
                this.log.info(`SUCCESS: Interface implementation ${interfaceId} added to Process Definition at ${pdAddress}`);
            });
    }

    async createActivityDefinition(processAddress: string, activityId: string, activityType: number,
        taskType: number, behavior: number, assignee: string, multiInstance: boolean, application: string,
        subProcessModelId: string, subProcessDefinitionId: string) {

        this.log.debug(`REQUEST: Create activity definition with data: ${JSON.stringify({
            processAddress,
            activityId,
            activityType,
            taskType,
            behavior,
            assignee,
            multiInstance,
            application,
            subProcessModelId,
            subProcessDefinitionId,
        })}`);

        await new ProcessDefinition.Contract(this.client, processAddress)
            .createActivityDefinition(
                BytesFromString(activityId),
                activityType,
                taskType,
                behavior,
                BytesFromString(assignee),
                multiInstance,
                BytesFromString(application),
                BytesFromString(subProcessModelId),
                BytesFromString(subProcessDefinitionId))
            .then(data => {
                if (data.error !== 1) throw new Error(ErrorCode.RUNTIME_ERROR);
                this.log.info(`SUCCESS: Activity definition ${activityId} created in process at ${processAddress}`);
            });
    }

    async createIntermediateEvent(
        processAddress: string,
        eventId: string,
        eventType: number,
        eventBehavior: number,
        dataPath: string,
        dataStorageId: string,
        dataStorage: string,
        timestampConstant: number,
        durationConstant: string
    ) {
        this.log.debug(`REQUEST: Create intermediate event with data: ${JSON.stringify({
            processAddress,
            eventId,
            eventType,
            eventBehavior,
            dataPath,
            dataStorageId,
            dataStorage,
            timestampConstant,
            durationConstant
        })}`);

        try {
            await new ProcessDefinition.Contract(this.client, processAddress)
                .createIntermediateEvent(
                    BytesFromString(eventId),
                    eventType,
                    eventBehavior,
                    BytesFromString(dataPath),
                    BytesFromString(dataStorageId),
                    dataStorage,
                    timestampConstant,
                    durationConstant
                );
        } catch (err) {
            this.log.error(`Failed to create intermediate event: ${err.stack} \n ${err.message}`);
        }
    }

    async setIntermediateEventDatetimeAndOffset(
        processAddress: string,
        eventId: string,
        datetimeDataPath: string,
        datetimeDataStorageId: string,
        datetimeDataStorage: string,
        offsetDataPath: string,
        offsetDataStorageId: string,
        offsetDataStorage: string
    ) {
        this.log.debug(`REQUEST: Set intermediate event datetime and offset with data: ${JSON.stringify({
            processAddress,
            eventId,
            datetimeDataPath,
            datetimeDataStorageId,
            datetimeDataStorage,
            offsetDataPath,
            offsetDataStorageId,
            offsetDataStorage
        })}`);
        
        await new ProcessDefinition.Contract(this.client, processAddress)
            .setIntermediateEventDatetimeAndOffset(
                BytesFromString(eventId),
                BytesFromString(datetimeDataPath),
                BytesFromString(datetimeDataStorageId),
                datetimeDataStorage,
                BytesFromString(offsetDataPath),
                BytesFromString(offsetDataStorageId),
                offsetDataStorage
            );
    }

    async setIntermediateEventTimerTarget(piAddress: string, eventInstanceId: string, targetTime: number) {
        this.log.debug(`REQUEST: Setting intermediate timer target with data: ${JSON.stringify({
            piAddress,
            eventInstanceId,
            targetTime
        })}`);

        await new ProcessInstance.Contract(this.client, piAddress)
            .setIntermediateEventTimerTarget(DecodeHex(eventInstanceId), targetTime);
    }

    async getIntermediateEventTimerTarget(piAddress: string, eventInstanceId: string) {
        this.log.debug(`REQUEST: Getting intermediate timer target with data: ${JSON.stringify({
            piAddress,
            eventInstanceId
        })}`);

        const timerTarget = await new ProcessInstance.Contract(this.client, piAddress)
            .getIntermediateEventTimerTarget(DecodeHex(eventInstanceId));
        
        return timerTarget;
    }

    async triggerIntermediateEvent(piAddress: string, eventInstanceId: string) {
        this.log.debug(`REQUEST: Triggering completion of Intermediate Event with data: ${JSON.stringify({
            piAddress,
            eventInstanceId
        })}`);

        const bpmService = this.manager.BpmService.address;

        await new ProcessInstance.Contract(this.client, piAddress)
            .triggerIntermediateEvent(DecodeHex(eventInstanceId), bpmService);
    }

    async createDataMapping(processAddress: string, id: string, direction: number, accessPath: string,
        dataPath: string, dataStorageId: string, dataStorage: string) {
        this.log.debug(`REQUEST: Create data mapping with data: ${JSON.stringify({
            processAddress,
            id,
            direction,
            accessPath,
            dataPath,
            dataStorageId,
            dataStorage,
        })}`);
        await new ProcessDefinition.Contract(this.client, processAddress)
            .createDataMapping(BytesFromString(id), direction, BytesFromString(accessPath),
                BytesFromString(dataPath), BytesFromString(dataStorageId), dataStorage);
    }

    async createGateway(processAddress: string, gatewayId: string, gatewayType: number) {
        this.log.debug(`REQUEST: Create gateway with data: ${JSON.stringify({ processAddress, gatewayId, gatewayType })}`);
        await new ProcessDefinition.Contract(this.client, processAddress)
            .createGateway(BytesFromString(gatewayId), gatewayType);
    }

    async createTransition(processAddress: string, sourceGraphElement: string, targetGraphElement: string) {
        this.log.debug(`REQUEST: Create transition with data: ${JSON.stringify({
            processAddress,
            sourceGraphElement,
            targetGraphElement,
        })}`);
        await new ProcessDefinition.Contract(this.client, processAddress)
            .createTransition(BytesFromString(sourceGraphElement), BytesFromString(targetGraphElement))
            .then(data => {
                if (data.error !== 1) throw new Error(`Error code creating transition from ${sourceGraphElement} to ${targetGraphElement} in process at ${processAddress}: ${data[0]}`);
                this.log.info(`SUCCESS: Transition created from ${sourceGraphElement} to ${targetGraphElement} in process at ${processAddress}`);
            });
    }

    async setDefaultTransition(processAddress: string, gatewayId: string, activityId: string) {
        this.log.debug(`REQUEST: Set default transition with data: ${JSON.stringify({ processAddress, gatewayId, activityId })}`);
        await new ProcessDefinition.Contract(this.client, processAddress)
            .setDefaultTransition(BytesFromString(gatewayId), BytesFromString(activityId));
        this.log.info(`SUCCESS: Default transition set from gateway ${gatewayId} to activity ${activityId} in process at ${processAddress}`);
    }

    async createTransitionCondition(processAddress: string, dataType: DataType, gatewayId: string, activityId: string, dataPath: string, dataStorageId: string, dataStorage: string, operator: number, value: string) {
        this.log.debug(`REQUEST: Create transition condition with data: ${JSON.stringify({
            processAddress,
            dataType,
            gatewayId,
            activityId,
            dataPath,
            dataStorageId,
            dataStorage,
            operator,
            value,
        })}`);

        const processDefinition = new ProcessDefinition.Contract(this.client, processAddress);

        switch (dataType) {
            case DataType.BOOLEAN:
                await processDefinition.createTransitionConditionForBool(
                    BytesFromString(gatewayId), BytesFromString(activityId), BytesFromString(dataPath),
                    BytesFromString(dataStorageId), dataStorage, operator, value === 'true'
                );
                break
            case DataType.STRING:
                await processDefinition.createTransitionConditionForString(
                    BytesFromString(gatewayId), BytesFromString(activityId), BytesFromString(dataPath),
                    BytesFromString(dataStorageId), dataStorage, operator, value
                );
                break
            case DataType.BYTES32:
                await processDefinition.createTransitionConditionForBytes32(
                    BytesFromString(gatewayId), BytesFromString(activityId), BytesFromString(dataPath),
                    BytesFromString(dataStorageId), dataStorage, operator, BytesFromString(value)
                );
                break
            case DataType.UINT:
                await processDefinition.createTransitionConditionForUint(
                    BytesFromString(gatewayId), BytesFromString(activityId), BytesFromString(dataPath),
                    BytesFromString(dataStorageId), dataStorage, operator, parseInt(value, 10)
                );
                break;
            case DataType.INT:
                await processDefinition.createTransitionConditionForInt(
                    BytesFromString(gatewayId), BytesFromString(activityId), BytesFromString(dataPath),
                    BytesFromString(dataStorageId), dataStorage, operator, parseInt(value, 10)
                );
                break
            case DataType.ADDRESS:
                await processDefinition.createTransitionConditionForAddress(
                    BytesFromString(gatewayId), BytesFromString(activityId), BytesFromString(dataPath),
                    BytesFromString(dataStorageId), dataStorage, operator, value
                );
                break
        }
        this.log.info(`SUCCESS: Created transition condition for transition between ${gatewayId} and ${activityId} in process at ${processAddress}`);
    }

    async getModelAddressFromId(modelId: string) {
        this.log.debug(`REQUEST: Get model address for model id ${modelId}`);
        return this.manager.ProcessModelRepository
            .getModel(BytesFromString(modelId))
            .then(data => data[0]);
    }

    async isValidProcess(processAddress: string) {
        this.log.debug(`REQUEST: Validate process definition at address: ${processAddress}`);
        return new ProcessDefinition.Contract(this.client, processAddress).validate()
            .then(data => {
                if (!data.result) throw new Error(`Invalid process definition at ${processAddress}: ${BytesToString(data.errorMessage)}`);
                else return true;
            });
    }

    async getStartActivity(processAddress: string) {
        this.log.debug(`REQUEST: Get start activity id for process at address: ${processAddress}`);
        return new ProcessDefinition.Contract(this.client, processAddress)
            .getStartActivity()
            .then(data => {
                const activityId = BytesToString(DecodeHex(BytesToString(data[0])));
                this.log.info(`SUCCESS: Retrieved start activity id ${activityId} for process at ${processAddress}`);
                return activityId;
            });
    }

    async getProcessInstanceCount() {
        this.log.debug('REQUEST: Get process instance count');
        return this.manager.BpmService
            .getNumberOfProcessInstances()
            .then(data => data.size);
    }

    async getProcessInstanceForActivity(activityInstanceId: string) {
        this.log.debug(`REQUEST: Get process instance for activity ${activityInstanceId}`);
        return this.manager.BpmService
            .getProcessInstanceForActivity(DecodeHex(activityInstanceId))
            .then(data => data[0]);
    }

    getProcessInstance(piAddress: string) {
        return new ProcessInstance.Contract(this.client, piAddress);
    }

    async getActivityInDataAsBool(userAddr: string, activityInstanceId: string, dataMappingId: string) {
        const piAddress = await this.getProcessInstanceForActivity(activityInstanceId);
        const payload = ProcessInstance.Encode(this.client).getActivityInDataAsBool(DecodeHex(activityInstanceId), BytesFromString(dataMappingId));
        const response = await this.callOnBehalfOf(userAddr, piAddress, payload);
        return ProcessInstance.Decode(this.client, DecodeHex(response)).getActivityInDataAsBool()[0];
    };

    async getActivityInDataAsString(userAddr: string, activityInstanceId: string, dataMappingId: string) {
        const piAddress = await this.getProcessInstanceForActivity(activityInstanceId);
        const payload = ProcessInstance.Encode(this.client).getActivityInDataAsString(DecodeHex(activityInstanceId), BytesFromString(dataMappingId));
        const response = await this.callOnBehalfOf(userAddr, piAddress, payload);
        return ProcessInstance.Decode(this.client, DecodeHex(response)).getActivityInDataAsString()[0];
    };

    async getActivityInDataAsBytes32(userAddr: string, activityInstanceId: string, dataMappingId: string) {
        const piAddress = await this.getProcessInstanceForActivity(activityInstanceId);
        const payload = ProcessInstance.Encode(this.client).getActivityInDataAsBytes32(DecodeHex(activityInstanceId), BytesFromString(dataMappingId));
        const response = await this.callOnBehalfOf(userAddr, piAddress, payload);
        return ProcessInstance.Decode(this.client, DecodeHex(response)).getActivityInDataAsBytes32()[0];
    };

    async getActivityInDataAsUint(userAddr: string, activityInstanceId: string, dataMappingId: string) {
        const piAddress = await this.getProcessInstanceForActivity(activityInstanceId);
        const payload = ProcessInstance.Encode(this.client).getActivityInDataAsUint(DecodeHex(activityInstanceId), BytesFromString(dataMappingId));
        const response = await this.callOnBehalfOf(userAddr, piAddress, payload);
        return ProcessInstance.Decode(this.client, DecodeHex(response)).getActivityInDataAsUint()[0];
    };

    async getActivityInDataAsInt(userAddr: string, activityInstanceId: string, dataMappingId: string) {
        const piAddress = await this.getProcessInstanceForActivity(activityInstanceId);
        const payload = ProcessInstance.Encode(this.client).getActivityInDataAsInt(DecodeHex(activityInstanceId), BytesFromString(dataMappingId));
        const response = await this.callOnBehalfOf(userAddr, piAddress, payload);
        return ProcessInstance.Decode(this.client, DecodeHex(response)).getActivityInDataAsInt()[0];
    };

    async getActivityInDataAsAddress(userAddr: string, activityInstanceId: string, dataMappingId: string) {
        const piAddress = await this.getProcessInstanceForActivity(activityInstanceId);
        const payload = ProcessInstance.Encode(this.client).getActivityInDataAsAddress(DecodeHex(activityInstanceId), BytesFromString(dataMappingId));
        const response = await this.callOnBehalfOf(userAddr, piAddress, payload);
        return ProcessInstance.Decode(this.client, DecodeHex(response)).getActivityInDataAsAddress()[0];
    };

    async setActivityOutDataAsBool(userAddr: string, activityInstanceId: string, dataMappingId: string, value: boolean) {
        const piAddress = await this.getProcessInstanceForActivity(activityInstanceId);
        const payload = ProcessInstance.Encode(this.client).setActivityOutDataAsBool(DecodeHex(activityInstanceId), BytesFromString(dataMappingId), value);
        await this.callOnBehalfOf(userAddr, piAddress, payload);
    };

    async setActivityOutDataAsString(userAddr: string, activityInstanceId: string, dataMappingId: string, value: string) {
        const piAddress = await this.getProcessInstanceForActivity(activityInstanceId);
        const payload = ProcessInstance.Encode(this.client).setActivityOutDataAsString(DecodeHex(activityInstanceId), BytesFromString(dataMappingId), value);
        await this.callOnBehalfOf(userAddr, piAddress, payload);
    };

    async setActivityOutDataAsBytes32(userAddr: string, activityInstanceId: string, dataMappingId: string, value: Buffer) {
        const piAddress = await this.getProcessInstanceForActivity(activityInstanceId);
        const payload = ProcessInstance.Encode(this.client).setActivityOutDataAsBytes32(DecodeHex(activityInstanceId), BytesFromString(dataMappingId), value);
        await this.callOnBehalfOf(userAddr, piAddress, payload);
    };

    async setActivityOutDataAsUint(userAddr: string, activityInstanceId: string, dataMappingId: string, value: number) {
        const piAddress = await this.getProcessInstanceForActivity(activityInstanceId);
        const payload = ProcessInstance.Encode(this.client).setActivityOutDataAsUint(DecodeHex(activityInstanceId), BytesFromString(dataMappingId), value);
        await this.callOnBehalfOf(userAddr, piAddress, payload);
    };

    async setActivityOutDataAsInt(userAddr: string, activityInstanceId: string, dataMappingId: string, value: number) {
        const piAddress = await this.getProcessInstanceForActivity(activityInstanceId);
        const payload = ProcessInstance.Encode(this.client).setActivityOutDataAsInt(DecodeHex(activityInstanceId), BytesFromString(dataMappingId), value);
        await this.callOnBehalfOf(userAddr, piAddress, payload);
    };

    async setActivityOutDataAsAddress(userAddr: string, activityInstanceId: string, dataMappingId: string, value: string) {
        const piAddress = await this.getProcessInstanceForActivity(activityInstanceId);
        const payload = ProcessInstance.Encode(this.client).setActivityOutDataAsString(DecodeHex(activityInstanceId), BytesFromString(dataMappingId), value);
        await this.callOnBehalfOf(userAddr, piAddress, payload);
    };

    async getDataMappingKeys(processDefinition: ProcessDefinition.Contract<CallTx>, activityId: string, direction: Direction): Promise<string[]> {
        this.log.debug(`REQUEST: Get data mapping keys for process definition at ${processDefinition}, activity ${activityId} and direction ${direction}`);
        const countPromise = direction === Direction.IN ?
            processDefinition.getInDataMappingKeys :
            processDefinition.getOutDataMappingKeys;

        return countPromise(BytesFromString(activityId))
            .then(data => {
                if (data[0] && Array.isArray(data[0])) {
                    const keys = data[0].map(key => BytesToString(key));
                    this.log.info(`SUCCESS: Retrieved data mapping keys for process definition at ${processDefinition}, activity ${activityId} and direction ${direction}: ${JSON.stringify(keys)}`);
                    return keys;
                  }
                  this.log.info(`SUCCESS: No data mapping keys found for process definition at ${processDefinition}, activity ${activityId} and direction ${direction}`);
                  return [];
            });
    }

    async getDataMappingDetails(processDefinition: ProcessDefinition.Contract<CallTx>, activityId: string, dataMappingIds: Array<string>, direction: Direction) {
        this.log.debug(`REQUEST: Get data mapping details for process definition at ${processDefinition}, activity ${activityId}, data mapping ids ${JSON.stringify(dataMappingIds)} and direction ${direction}`);
        const dataPromises: Promise<{
            dataMappingId: Buffer;
            accessPath: Buffer;
            dataPath: Buffer;
            dataStorageId: Buffer;
            dataStorage: string;
        }>[] = [];
        dataMappingIds.forEach((dataMappingId) => {
            const getter = direction === Direction.IN ?
                processDefinition.getInDataMappingDetails : processDefinition.getOutDataMappingDetails;
            dataPromises.push(getter(BytesFromString(activityId), BytesFromString(dataMappingId)));
        });
        return Promise.all(dataPromises);
    }

    async getDataMappingDetailsForActivity(pdAddress: string, activityId: string, dataMappingIds: Array<string>, direction: Direction) {
        this.log.debug(`REQUEST: Get ${direction ? 'out-' : 'in-'}data mapping details for activity ${activityId} in process definition at ${pdAddress}`);

        const processDefinition = new ProcessDefinition.Contract(this.client, pdAddress)
        // NOTE: activityId are hex converted inside getDataMappingKeys and not here
        const keys = dataMappingIds || (await this.getDataMappingKeys(processDefinition, activityId, direction));
        // NOTE: activityId and dataMappingIds are hex converted inside getDataMappingDetails and not here
        const details = await this.getDataMappingDetails(processDefinition, activityId, keys, direction);
        return details;
    }

    async getActivityInstanceData(piAddress: string, activityInstanceId: string) {
        this.log.debug(`REQUEST: Get activity instance data for activity id ${activityInstanceId} in process instance at address ${piAddress}`);
        const data = await this.manager.BpmService.getActivityInstanceData(piAddress, DecodeHex(activityInstanceId));
        return {
            activityId: data.activityId,
            created: data.created,
            completed: data.completed,
            performer: data.performer,
            completedBy: data.completedBy,
            state: data.state,
        };
    }

    async getActivityInstanceIDAtIndex(piAddress: string, index: number) {
        return new ProcessInstance.Contract(this.client, piAddress)
            .getActivityInstanceAtIndex(index).then(data => data[0])
            .then(data => BytesToString(data));
    }

    // TODO: type guard value
    async completeActivity(actingUserAddress: string, activityInstanceId: string, dataMappingId?: string | null, dataType?: DataType, value?: boolean | string | Buffer | number) {
        this.log.debug(`REQUEST: Complete task ${activityInstanceId} by user ${actingUserAddress}`);

        const activityInstanceID = DecodeHex(activityInstanceId);

        const piAddress = await this.manager.BpmService
            .getProcessInstanceForActivity(activityInstanceID)
            .then(data => data[0]);
        this.log.info(`Found process instance ${piAddress} for activity instance ID ${activityInstanceId}`);

        const bpmService = this.manager.BpmService.address;
        let payload: string;
        if (dataMappingId) {
            this.log.info(`Completing activity with OUT data mapping ID:Value (${dataMappingId}:${value}) for activityInstance ${activityInstanceId} in process instance ${piAddress}`);
            const hexDataMappingId = BytesFromString(dataMappingId);
            switch (dataType) {
                case DataType.BOOLEAN:
                    payload = ProcessInstance.Encode(this.client)
                        .completeActivityWithBoolData(activityInstanceID, bpmService, hexDataMappingId, value as boolean)
                    break;
                case DataType.STRING:
                    payload = ProcessInstance.Encode(this.client)
                        .completeActivityWithStringData(activityInstanceID, bpmService, hexDataMappingId, value as string);
                    break;
                case DataType.BYTES32:
                    payload = ProcessInstance.Encode(this.client)
                        .completeActivityWithBytes32Data(activityInstanceID, bpmService, hexDataMappingId, value as Buffer);
                    break;
                case DataType.UINT:
                    payload = ProcessInstance.Encode(this.client)
                        .completeActivityWithUintData(activityInstanceID, bpmService, hexDataMappingId, value as number);
                    break;
                case DataType.INT:
                    payload = ProcessInstance.Encode(this.client)
                        .completeActivityWithIntData(activityInstanceID, bpmService, hexDataMappingId, value as number);
                    break;
                case DataType.ADDRESS:
                    payload = ProcessInstance.Encode(this.client)
                        .completeActivityWithAddressData(activityInstanceID, bpmService, hexDataMappingId, value as string);
                    break;
                default:
                    throw new Error(`Unsupported dataType parameter: ${dataType}`)
            }
        } else {
            payload = ProcessInstance.Encode(this.client).completeActivity(activityInstanceID, bpmService);
        }
        const returnData = await this.callOnBehalfOf(actingUserAddress, piAddress, payload);
        const data = ProcessInstance.Decode(this.client, DecodeHex(returnData)).completeActivity();
        const error = data.error.valueOf();

        switch(error) {
            case 1:
                return
            case 1001:
                throw new Error(`No activity instance found with ID ${activityInstanceId}`);
            case 4103:
                throw new Error(`User ${actingUserAddress} not authorized to complete activity ID ${activityInstanceId}`);
            default:
                throw new Error(`Completing activity instance ID ${activityInstanceId} by user ${actingUserAddress} returned error code: ${error}`);
        }
    }

    async addExternalAddressToEcosystem(externalAddress: string, ecosystemAddress: string) {
        this.log.debug(`REQUEST: Add external address ${externalAddress} to Ecosystem at ${ecosystemAddress}`);
        await new Ecosystem.Contract(this.client, ecosystemAddress).addExternalAddress(externalAddress);
        this.log.info(`SUCCESS: Added external address ${externalAddress} to ecosystem at ${ecosystemAddress}`);
    }

    async createUserInEcosystem(user: { username: string; }, ecosystemAddress: string) {
        this.log.debug(`REQUEST: Create a new user with ID: ${user.username} in ecosystem at ${ecosystemAddress}`);
        return this.manager.ParticipantsManager
            .createUserAccount(DecodeHex(user.username), '0x0', ecosystemAddress)
            .then(data => {
                this.log.info(`SUCCESS: Created new user ${user.username} at address ${data.userAccount}`);
                return data.userAccount;
            });
    }

    async createUser(user: { username: string; }) {
        return this.createUserInEcosystem(user, this.ecosystem);
    }

    async getUserByIdAndEcosystem(id: string, ecosystemAddress: string) {
        this.log.trace(`REQUEST: Get user by id: ${id} in ecosystem at ${ecosystemAddress}`);
        return new Ecosystem.Contract(this.client, ecosystemAddress)
            .getUserAccount(DecodeHex(id))
            .then(data => {
                this.log.trace(`SUCCESS: Retrieved user address ${data._account} by id ${id} and ecosystem ${ecosystemAddress}`);
                return data._account;
            })
    }

    async getUserByUsername(username: string) {
        return this.getUserByIdAndEcosystem(username, this.ecosystem);
    }

    async getUserByUserId(userid: string) {
        return this.getUserByIdAndEcosystem(userid, this.ecosystem);
    }

    async addUserToEcosystem(username: string, address: string) {
        this.log.debug(`REQUEST: Add user ${username} with address ${address} to ecosystem at ${this.ecosystem}`);
        await new Ecosystem.Contract(this.client, this.ecosystem)
            .addUserAccount(DecodeHex(username), address);
        this.log.info(`SUCCESS: Successfully added user ${username} with address ${address} to ecosystem at ${this.ecosystem}`);
    }

    async migrateUserAccountInEcosystem(userAddress: string, migrateFromId: string, migrateToId: string) {
        this.log.debug(`REQUEST: Migrate user account ${userAddress} from id ${migrateFromId} to id ${migrateToId}`);
        return new Ecosystem.Contract(this.client, this.ecosystem)
            .migrateUserAccount(userAddress, DecodeHex(migrateFromId), DecodeHex(migrateToId));
    }

    async createOrganization(org: { approvers: string[]; }) {
        this.log.debug(`REQUEST: Create organization with: ${JSON.stringify(org)}`);
        return this.manager.ParticipantsManager
            .createOrganization(org.approvers ? org.approvers : [])
            .then(data => {
                if (data[0] !== 1) throw new Error(`Error code creating new organization: ${data[0]}`);
                this.log.info(`SUCCESS: Created new organization at address ${data[1]}, with approvers ${org.approvers}`);
                return data[1];
            });
    }

    async addUserToOrganization(userAddress: any, organizationAddress: any, actingUserAddress: any) {
        this.log.debug('REQUEST: Add user %s to organization %s', userAddress, organizationAddress);
        const payload = Organization.Encode(this.client).addUser(userAddress);
        const response = await this.callOnBehalfOf(actingUserAddress, organizationAddress, payload);
        const data = Organization.Decode(this.client, DecodeHex(response)).addUser();
        if (!data.successful) throw new Error(`Failed to add user ${userAddress} to organization ${organizationAddress}!: ${response}`);
        else this.log.info(`SUCCESS: User ${userAddress} successfully added to organization ${organizationAddress}`);
    }

    async removeUserFromOrganization(userAddress: string, organizationAddress: string, actingUserAddress: string) {
        this.log.debug('REQUEST: Remove user %s from organization %s', userAddress, organizationAddress);
        const payload = Organization.Encode(this.client).removeUser(userAddress);
        const response = await this.callOnBehalfOf(actingUserAddress, organizationAddress, payload);
        const data = Organization.Decode(this.client, DecodeHex(response)).removeUser();
        if (!data.successful) throw new Error(`Failed to remove user ${userAddress} from organization ${organizationAddress}!: ${response}`);
        else this.log.info(`SUCCESS: User ${userAddress} successfully added to organization ${organizationAddress}`);
    }

    async addApproverToOrganization(approverAddress: string, organizationAddress: string, actingUserAddress: string) {
        this.log.debug(`REQUEST: Add approver ${approverAddress} to organization ${organizationAddress}`);
        const payload = Organization.Encode(this.client).addApprover(approverAddress);
        await this.callOnBehalfOf(actingUserAddress, organizationAddress, payload);
        this.log.info(`SUCCESS: Approver ${approverAddress} successfully added to organization ${organizationAddress}`);
    }

    async removeApproverFromOrganization(approverAddress: string, organizationAddress: string, actingUserAddress: string) {
        this.log.debug(`REQUEST: Remove approver ${approverAddress} from organization ${organizationAddress}`);
        const payload = Organization.Encode(this.client).removeApprover(approverAddress);
        await this.callOnBehalfOf(actingUserAddress, organizationAddress, payload);
        this.log.info(`SUCCESS: Approver ${approverAddress} successfully removed from organization ${organizationAddress}`);
    }

    async createDepartment(organizationAddress: string, id: string, actingUserAddress: string) {
        this.log.debug(`REQUEST: Create department ${id} in organization ${organizationAddress}`);
        const payload = Organization.Encode(this.client).addDepartment(DecodeHex(id));
        const response = await this.callOnBehalfOf(actingUserAddress, organizationAddress, payload);
        const data = Organization.Decode(this.client, DecodeHex(response)).addDepartment();
        if (!data[0]) throw new Error(`Failed to create department ID ${id} in organization ${organizationAddress}!: ${response}`);
        else this.log.info(`SUCCESS: Department ID ${id} successfully created in organization ${organizationAddress}`);
    }

    async removeDepartment(organizationAddress: string, id: string, actingUserAddress: string) {
        this.log.debug(`REQUEST: Remove department ${id} from organization ${organizationAddress}`);
        const payload = Organization.Encode(this.client).removeDepartment(DecodeHex(id));
        const response = await this.callOnBehalfOf(actingUserAddress, organizationAddress, payload);
        const data = Organization.Decode(this.client, DecodeHex(response)).removeDepartment();
        if (!data.successful) throw new Error(`Failed to remove department ID ${id} from organization ${organizationAddress}!: ${response}`);
        else this.log.info(`SUCCESS: Department ID ${id} successfully removed from organization ${organizationAddress}`);
    }

    async addDepartmentUser(organizationAddress: string, depId: string, userAddress: string, actingUserAddress: string) {
        this.log.debug(`REQUEST: Add user ${userAddress} to department ${depId} in organization ${organizationAddress}`);
        const payload = Organization.Encode(this.client).addUserToDepartment(userAddress, DecodeHex(depId));
        const response = await this.callOnBehalfOf(actingUserAddress, organizationAddress, payload);
        const data = Organization.Decode(this.client, DecodeHex(response)).addUserToDepartment();
        if (!data.successful) throw new Error(`Failed to add user ${userAddress} to department ID ${depId} in organization ${organizationAddress}!: ${response}`);
        else this.log.info(`SUCCESS: User ${userAddress} successfully added to department ${depId} in organization ${organizationAddress}`);
    }

    async removeDepartmentUser(organizationAddress: string, depId: string, userAddress: string, actingUserAddress: string) {
        this.log.debug(`REQUEST: Remove user ${userAddress} from department ${depId} in organization ${organizationAddress}`);
        const payload = Organization.Encode(this.client).removeUserFromDepartment(userAddress, DecodeHex(depId));
        const response = await this.callOnBehalfOf(actingUserAddress, organizationAddress, payload);
        const data = Organization.Decode(this.client, DecodeHex(response)).removeUserFromDepartment();
        if (!data[0]) throw new Error(`Failed to remove user ${userAddress} from department ID ${depId} in organization ${organizationAddress}!: ${response}`);
        else this.log.info(`SUCCESS: User ${userAddress} successfully removed from department ${depId} in organization ${organizationAddress}`);
    }
}

export async function NewContracts(url: string, account: string, ecosystemName: string): Promise<Contracts> {
    const client = new Client(url, account);
    const manager = await NewManager(client);

    let ecosystemAddress = await GetFromNameRegistry(client, ecosystemName);
    if (!ecosystemAddress) {
        ecosystemAddress = await RegisterEcosystem(client, manager, account, ecosystemName);
    }

    return new Contracts(client, manager, ecosystemAddress);
}

export class SyncContracts extends Contracts {
  vent: VentListener;
  watch: BurrowWatcher;

  constructor(contracts: Contracts, vent: VentListener) {
    super(contracts.client, contracts.manager, contracts.ecosystem);

    this.vent = vent;
    this.watch = this.vent.NewWatcher();

    this.client.interceptor = async (data) => {
      this.watch.update(data);
      return data;
    };
  }

  async do<T>(func: (contracts: this) => Promise<T>): Promise<T> {
    const result = await func(this);
    await this.sync();
    return result;
  }

  async sync() {
    return this.watch.wait();
  }
}

export async function NewSync(contracts: Contracts, vent: VentListener) {
  await vent.listen();
  return new SyncContracts(contracts, vent);
}
