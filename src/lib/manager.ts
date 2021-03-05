import { Client } from "./client";
import { CallTx } from "@hyperledger/burrow/proto/payload_pb";
import { DOUG } from "../commons-management/DOUG.abi";
import { EcosystemRegistry } from "../commons-auth/EcosystemRegistry.abi";
import { ParticipantsManager } from "../commons-auth/ParticipantsManager.abi";
import { ArchetypeRegistry } from "../agreements/ArchetypeRegistry.abi";
import { ActiveAgreementRegistry } from "../agreements/ActiveAgreementRegistry.abi";
import { ProcessModelRepository } from "../bpm-model/ProcessModelRepository.abi";
import { ApplicationRegistry } from "../bpm-runtime/ApplicationRegistry.abi";
import { BpmService } from "../bpm-runtime/BpmService.abi";
import { GetFromNameRegistry } from "./utils";
import { Contracts } from "./constants";
import { Completables } from "../agreements/Completables.abi";
import { AgreementDates } from "../agreements/AgreementDates.abi";
import { AgreementRequestResponse } from "../agreements/AgreementRequestResponse.abi";

async function lookup(doug: DOUG.Contract<CallTx>, contract: string) {
  const result = await doug.lookup(contract);
  return result.contractAddress;
}

export type Manager = {
  EcosystemRegistry: EcosystemRegistry.Contract<CallTx>;
  ParticipantsManager: ParticipantsManager.Contract<CallTx>;
  ArchetypeRegistry: ArchetypeRegistry.Contract<CallTx>;
  ActiveAgreementRegistry: ActiveAgreementRegistry.Contract<CallTx>;
  ProcessModelRepository: ProcessModelRepository.Contract<CallTx>;
  ApplicationRegistry: ApplicationRegistry.Contract<CallTx>;
  BpmService: BpmService.Contract<CallTx>;
  Completables: Completables.Contract<CallTx>;
  AgreementDates: AgreementDates.Contract<CallTx>;
  AgreementRequestResponse: AgreementRequestResponse.Contract<CallTx>;
};

export async function NewManager(client: Client): Promise<Manager> {
  const addr = await GetFromNameRegistry(client, "DOUG");
  const doug = new DOUG.Contract(client, addr);

  const ecosystemRegistry = lookup(doug, Contracts.EcosystemRegistry);
  const participantsManager = lookup(doug, Contracts.ParticipantsManager);
  const archetypeRegistry = lookup(doug, Contracts.ArchetypeRegistry);
  const activeAgreementRegistry = lookup(
    doug,
    Contracts.ActiveAgreementRegistry
  );
  const processModelRepository = lookup(doug, Contracts.ProcessModelRepository);
  const applicationRegistry = lookup(doug, Contracts.ApplicationRegistry);
  const bpmService = lookup(doug, Contracts.BpmService);
  const completables = lookup(doug, Contracts.Completables);
  const agreementDates = lookup(doug, Contracts.AgreementDates);
  const agreementRequestResponse = lookup(
    doug,
    Contracts.AgreementRequestResponse
  );

  return {
    EcosystemRegistry: new EcosystemRegistry.Contract(
      client,
      await ecosystemRegistry
    ),
    ParticipantsManager: new ParticipantsManager.Contract(
      client,
      await participantsManager
    ),
    ArchetypeRegistry: new ArchetypeRegistry.Contract(
      client,
      await archetypeRegistry
    ),
    ActiveAgreementRegistry: new ActiveAgreementRegistry.Contract(
      client,
      await activeAgreementRegistry
    ),
    ProcessModelRepository: new ProcessModelRepository.Contract(
      client,
      await processModelRepository
    ),
    ApplicationRegistry: new ApplicationRegistry.Contract(
      client,
      await applicationRegistry
    ),
    BpmService: new BpmService.Contract(client, await bpmService),
    Completables: new Completables.Contract(client, await completables),
    AgreementDates: new AgreementDates.Contract(client, await agreementDates),
    AgreementRequestResponse: new AgreementRequestResponse.Contract(
      client,
      await agreementRequestResponse
    ),
  };
}
