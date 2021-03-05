export enum Contracts {
  DOUG = "DOUG",
  EcosystemRegistry = "EcosystemRegistry",
  ParticipantsManager = "ParticipantsManager",
  ArchetypeRegistry = "ArchetypeRegistry",
  ActiveAgreementRegistry = "ActiveAgreementRegistry",
  ProcessModelRepository = "ProcessModelRepository",
  ApplicationRegistry = "ApplicationRegistry",
  BpmService = "BpmService",
  Completables = "Completables",
  DateRelations = "DateRelations",
  AgreementDates = "AgreementDates",
  AgreementRequestResponse = "AgreementRequestResponse",
}

export enum Libraries {
  ErrorsLib = "ErrorsLib",
  TypeUtilsLib = "TypeUtilsLib",
  ArrayUtilsLib = "ArrayUtilsLib",
  MappingsLib = "MappingsLib",
  DataStorageUtils = "DataStorageUtils",
  ERC165Utils = "ERC165Utils",
  BpmModelLib = "BpmModelLib",
  BpmRuntimeLib = "BpmRuntimeLib",
  AgreementsAPI = "AgreementsAPI",
  Strings = "Strings",
}

export enum Direction {
  IN = 0,
  OUT,
}

export const ErrorCode = {
  UNAUTHORIZED: "ERR403",
  RESOURCE_NOT_FOUND: "ERR404",
  RESOURCE_ALREADY_EXISTS: "ERR409",
  INVALID_INPUT: "ERR422",
  RUNTIME_ERROR: "ERR500",
  INVALID_STATE: "ERR600",
  INVALID_PARAMETER_STATE: "ERR601",
  OVERWRITE_NOT_ALLOWED: "ERR610",
  NULL_PARAMETER_NOT_ALLOWED: "ERR611",
  DEPENDENCY_NOT_FOUND: "ERR704",
};
