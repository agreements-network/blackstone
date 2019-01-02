[
  {
    "TableName": "AGREEMENTS",
    "Filter": "Log1Text = 'AN://agreements'",
    "Columns": {
      "agreement_address": {
        "name": "agreement_address",
        "type": "address",
        "primary": true
      },
      "archetype_address": {
        "name": "archetype_address",
        "type": "address"
      },
      "name": {
        "name": "name",
        "type": "string"
      },
      "creator": {
        "name": "creator",
        "type": "address"
      },
      "is_private": {
        "name": "is_private",
        "type": "bool"
      },
      "legal_state": {
        "name": "legal_state",
        "type": "uint8"
      },
      "max_event_count": {
        "name": "max_event_count",
        "type": "uint32"
      },
      "formation_process_instance": {
        "name": "formation_process_instance",
        "type": "address"
      },
      "execution_process_instance": {
        "name": "execution_process_instance",
        "type": "address"
      },
      "hoard_address": {
        "name": "hoard_address",
        "type": "bytes32"
      },
      "hoard_secret": {
        "name": "hoard_secret",
        "type": "bytes32"
      },
      "event_log_hoard_address": {
        "name": "event_log_hoard_address",
        "type": "bytes32"
      },
      "event_log_hoard_secret": {
        "name": "event_log_hoard_secret",
        "type": "bytes32"
      }
    }
  },
  {
    "TableName": "AGREEMENT_COLLECTIONS",
    "Filter": "Log1Text = 'AN://agreement-collections'",
    "Columns": {
      "collection_id": {
        "name": "collection_id",
        "type": "bytes32",
        "primary": true
      },
      "name": {
        "name": "name",
        "type": "string"
      },
      "author": {
        "name": "author",
        "type": "address"
      },
      "collection_type": {
        "name": "collection_type",
        "type": "uint8"
      },
      "package_id": {
        "name": "package_id",
        "type": "bytes32"
      }
    }
  },
  {
    "TableName": "AGREEMENT_TO_PARTY",
    "Filter": "Log1Text = 'AN://agreement-to-party'",
    "Columns": {
      "agreement_address": {
        "name": "agreement_address",
        "type": "address",
        "primary": true
      },
      "party": {
        "name": "party",
        "type": "address",
        "primary": true
      },
      "signed_by": {
        "name": "signed_by",
        "type": "address"
      },
      "signature_timestamp": {
        "name": "signature_timestamp",
        "type": "uint"
      }
    }
  },
  {
    "TableName": "AGREEMENT_TO_COLLECTION",
    "Filter": "Log1Text = 'AN://agreement-to-collection'",
    "Columns": {
      "collection_id": {
        "name": "collection_id",
        "type": "bytes32",
        "primary": true
      },
      "agreement_address": {
        "name": "agreement_address",
        "type": "address",
        "primary": true
      },
      "agreement_name": {
        "name": "agreement_name",
        "type": "string"
      },
      "archetype_address": {
        "name": "archetype_address",
        "type": "address"
      }
    }
  },
  {
    "TableName": "GOVERNING_AGREEMENTS",
    "Filter": "Log1Text = 'AN://governing-agreements'",
    "Columns": {
      "agreement_address": {
        "name": "agreement_address",
        "type": "address",
        "primary": true
      },
      "governing_agreement_address": {
        "name": "governing_agreement_address",
        "type": "address",
        "primary": true
      },
      "governing_agreement_name": {
        "name": "governing_agreement_name",
        "type": "string"
      }
    }
  },
  {
    "TableName": "ARCHETYPES",
    "Filter": "Log1Text = 'AN://archetypes'",
    "Columns": {
      "archetype_address": {
        "name": "archetype_address",
        "type": "address",
        "primary": true
      },
      "name": {
        "name": "name",
        "type": "string"
      },
      "description": {
        "name": "description",
        "type": "string"
      },
      "price": {
        "name": "price",
        "type": "uint32"
      },
      "author": {
        "name": "author",
        "type": "address"
      },
      "active": {
        "name": "active",
        "type": "bool"
      },
      "is_private": {
        "name": "is_private",
        "type": "bool"
      },
      "successor": {
        "name": "successor",
        "type": "address"
      },
      "formation_process_Definition": {
        "name": "formation_process_Definition",
        "type": "address"
      },
      "execution_process_Definition": {
        "name": "execution_process_Definition",
        "type": "address"
      }
    }
  },
  {
    "TableName": "ARCHETYPE_PACKAGES",
    "Filter": "Log1Text = 'AN://archetype-packages'",
    "Columns": {
      "package_id": {
        "name": "package_id",
        "type": "bytes32",
        "primary": true
      },
      "name": {
        "name": "name",
        "type": "string"
      },
      "description": {
        "name": "description",
        "type": "string"
      },
      "author": {
        "name": "author",
        "type": "address"
      },
      "is_private": {
        "name": "is_private",
        "type": "bool"
      },
      "active": {
        "name": "active",
        "type": "bool"
      }
    }
  },
  {
    "TableName": "ARCHETYPE_TO_PACKAGE",
    "Filter": "Log1Text = 'AN://archetype-to-package'",
    "Columns": {
      "package_id": {
        "name": "package_id",
        "type": "bytes32",
        "primary": true
      },
      "archetype_address": {
        "name": "archetype_address",
        "type": "address",
        "primary": true
      },
      "archetype_name": {
        "name": "archetype_name",
        "type": "string"
      }
    }
  },
  {
    "TableName": "ARCHETYPE_PARAMETERS",
    "Filter": "Log1Text = 'AN://archetype/parameters'",
    "Columns": {
      "archetype_address": {
        "name": "archetype_address",
        "type": "address",
        "primary": true
      },
      "parameter_name": {
        "name": "parameter_name",
        "type": "bytes32",
        "primary": true,
        "bytesToString": true
      },
      "parameter_type": {
        "name": "parameter_type",
        "type": "uint8"
      },
      "position": {
        "name": "position",
        "type": "uint256"
      }
    }
  },
  {
    "TableName": "ARCHETYPE_DOCUMENTS",
    "Filter": "Log1Text = 'AN://archetype/documents'",
    "Columns": {
      "archetype_address": {
        "name": "archetype_address",
        "type": "address",
        "primary": true
      },
      "document_key": {
        "name": "document_key",
        "type": "bytes32",
        "primary": true
      },
      "hoard_address": {
        "name": "hoard_address",
        "type": "bytes32"
      },
      "secret_key": {
        "name": "secret_key",
        "type": "bytes32"
      }
    }
  },
  {
    "TableName": "ARCHETYPE_JURISDICTIONS",
    "Filter": "Log1Text = 'AN://archetype/jurisdictions'",
    "Columns": {
      "archetype_address": {
        "name": "archetype_address",
        "type": "address",
        "primary": true
      },
      "country": {
        "name": "country",
        "type": "bytes2",
        "primary": true,
        "bytesToString": true
      },
      "region": {
        "name": "region",
        "type": "bytes32",
        "primary": true
      }
    }
  },
  {
    "TableName": "GOVERNING_ARCHETYPES",
    "Filter": "Log1Text = 'AN://governing-archetypes'",
    "Columns": {
      "archetype_address": {
        "name": "archetype_address",
        "type": "address",
        "primary": true
      },
      "governing_archetype_address": {
        "name": "governing_archetype_address",
        "type": "address",
        "primary": true
      },
      "governing_archetype_name": {
        "name": "governing_archetype_name",
        "type": "string"
      }
    }
  },
  {
    "TableName": "ACTIVITY_INSTANCES",
    "Filter": "Log1Text = 'AN://activity-instances'",
    "Columns": {
      "activity_instance_id": {
        "name": "activity_instance_id",
        "type": "bytes32",
        "primary": true
      },
      "activity_id": {
        "name": "activity_id",
        "type": "bytes32",
        "bytesToString": true
      },
      "process_instance_address": {
        "name": "process_instance_address",
        "type": "address"
      },
      "created": {
        "name": "created",
        "type": "uint"
      },
      "completed": {
        "name": "completed",
        "type": "uint"
      },
      "performer": {
        "name": "performer",
        "type": "address"
      },
      "completed_by": {
        "name": "completed_by",
        "type": "address"
      },
      "state": {
        "name": "state",
        "type": "uint8"
      }
    }
  },
  {
    "TableName": "PROCESS_INSTANCES",
    "Filter": "Log1Text = 'AN://process-instances'",
    "Columns": {
      "process_instance_address": {
        "name": "process_instance_address",
        "type": "address",
        "primary": true
      },
      "process_definition_address": {
        "name": "process_definition_address",
        "type": "address"
      },
      "state": {
        "name": "state",
        "type": "uint8"
      },
      "started_by": {
        "name": "started_by",
        "type": "address"
      }
    }
  },
  {
    "TableName": "ACTIVITY_DEFINITIONS",
    "Filter": "Log1Text = 'AN://activity-definitions'",
    "Columns": {
      "activity_id": {
        "name": "activity_id",
        "type": "bytes32",
        "primary": true,
        "bytesToString": true
      },
      "model_address": {
        "name": "model_address",
        "type": "address",
        "primary": true
      },
      "process_definition_address": {
        "name": "process_definition_address",
        "type": "address",
        "primary": true
      },
      "activity_type": {
        "name": "activity_type",
        "type": "uint8"
      },
      "task_type": {
        "name": "task_type",
        "type": "uint8"
      },
      "task_behavior": {
        "name": "task_behavior",
        "type": "uint8"
      },
      "participant_id": {
        "name": "participant_id",
        "type": "bytes32",
        "bytesToString": true
      },
      "multi_instance": {
        "name": "multi_instance",
        "type": "bool"
      },
      "application": {
        "name": "application",
        "type": "bytes32",
        "bytesToString": true
      },
      "sub_process_model_id": {
        "name": "sub_process_model_id",
        "type": "bytes32",
        "bytesToString": true
      },
      "sub_process_definition_id": {
        "name": "sub_process_definition_id",
        "type": "bytes32",
        "bytesToString": true
      }
    }
  },
  {
    "TableName": "PROCESS_DEFINITIONS",
    "Filter": "Log1Text = 'AN://process-definitions'",
    "Columns": {
      "process_definition_address": {
        "name": "process_definition_address",
        "type": "address",
        "primary": true
      },
      "id": {
        "name": "id",
        "type": "bytes32",
        "bytesToString": true
      },
      "interface_id": {
        "name": "interface_id",
        "type": "bytes32",
        "bytesToString": true
      },
      "model_id": {
        "name": "model_id",
        "type": "bytes32",
        "bytesToString": true
      },
      "model_address": {
        "name": "model_address",
        "type": "address"
      }
    }
  },
  {
    "TableName": "PROCESS_MODELS",
    "Filter": "Log1Text = 'AN://process-models'",
    "Columns": {
      "model_address": {
        "name": "model_address",
        "type": "address",
        "primary": true
      },
      "id": {
        "name": "id",
        "type": "bytes32",
        "bytesToString": true
      },
      "name": {
        "name": "name",
        "type": "string"
      },
      "version_major": {
        "name": "version_major",
        "type": "uint"
      },
      "version_minor": {
        "name": "version_minor",
        "type": "uint"
      },
      "version_patch": {
        "name": "version_patch",
        "type": "uint"
      },
      "author": {
        "name": "author",
        "type": "address"
      },
      "is_private": {
        "name": "is_private",
        "type": "bool"
      },
      "active": {
        "name": "active",
        "type": "bool"
      },
      "diagram_address": {
        "name": "diagram_address",
        "type": "bytes32"
      },
      "diagram_secret": {
        "name": "diagram_secret",
        "type": "bytes32"
      }
    }
  },
  {
    "TableName": "APPLICATIONS",
    "Filter": "Log1Text = 'AN://applications'",
    "Columns": {
      "application_id": {
        "name": "application_id",
        "type": "bytes32",
        "primary": true,
        "bytesToString": true
      },
      "application_type": {
        "name": "application_type",
        "type": "uint8"
      },
      "location": {
        "name": "location",
        "type": "address"
      },
      "method": {
        "name": "method",
        "type": "bytes4"
      },
      "web_form": {
        "name": "web_form",
        "type": "bytes32",
        "bytesToString": true
      },
      "access_point_count": {
        "name": "access_point_count",
        "type": "uint"
      }
    }
  },
  {
    "TableName": "APPLICATION_ACCESS_POINTS",
    "Filter": "Log1Text = 'AN://applications/access-points'",
    "Columns": {
      "application_id": {
        "name": "application_id",
        "type": "bytes32",
        "primary": true,
        "bytesToString": true
      },
      "access_point_id": {
        "name": "access_point_id",
        "type": "bytes32",
        "primary": true,
        "bytesToString": true
      },
      "data_type": {
        "name": "data_type",
        "type": "uint8"
      },
      "direction": {
        "name": "direction",
        "type": "uint8"
      }
    }
  },
  {
    "TableName": "PROCESS_DATA",
    "Filter": "Log1Text = 'AN://process-instance/data'",
    "Columns": {
      "process_instance_address": {
        "name": "process_instance_address",
        "type": "address",
        "primary": true
      },
      "data_id": {
        "name": "data_id",
        "type": "bytes32",
        "primary": true,
        "bytesToString": true
      },
      "bool_value": {
        "name": "bool_value",
        "type": "bool"
      },
      "uint_value": {
        "name": "uint_value",
        "type": "uint"
      },
      "int_value": {
        "name": "int_value",
        "type": "int"
      },
      "bytes32_value": {
        "name": "bytes32_value",
        "type": "bytes32",
        "bytesToString": true
      },
      "address_value": {
        "name": "address_value",
        "type": "address"
      },
      "string_value": {
        "name": "string_value",
        "type": "string"
      }
    }
  },
  {
    "TableName": "PROCESS_INSTANCE_ADDRESS_SCOPES",
    "Filter": "Log1Text = 'AN://process-instance/scopes'",
    "Columns": {
      "process_instance_address": {
        "name": "process_instance_address",
        "type": "address",
        "primary": true
      },
      "addres_scope_key": {
        "name": "addres_scope_key",
        "type": "bytes32",
        "primary": true
      },
      "key_address": {
        "name": "key_address",
        "type": "address"
      },
      "key_context": {
        "name": "key_context",
        "type": "bytes32",
        "bytesToString": true
      },
      "fixed_scope": {
        "name": "fixed_scope",
        "type": "bytes32"
      },
      "data_path": {
        "name": "data_path",
        "type": "bytes32",
        "bytesToString": true
      },
      "data_storage_id": {
        "name": "data_storage_id",
        "type": "bytes32",
        "bytesToString": true
      },
      "data_storage": {
        "name": "data_storage",
        "type": "address"
      }
    }
  },
  {
    "TableName": "COUNTRIES",
    "Filter": "Log1Text = 'AN://standards/countries'",
    "Columns": {
      "name": {
        "name": "name",
        "type": "string",
        "primary": true
      },
      "alpha2": {
        "name": "alpha2",
        "type": "bytes2",
        "bytesToString": true
      },
      "alpha3": {
        "name": "alpha3",
        "type": "bytes3",
        "bytesToString": true
      },
      "m49": {
        "name": "m49",
        "type": "bytes3",
        "bytesToString": true
      }
    }
  },
  {
    "TableName": "REGIONS",
    "Filter": "Log1Text = 'AN://standards/regions'",
    "Columns": {
      "country": {
        "name": "country",
        "type": "bytes2",
        "primary": true,
        "bytesToString": true
      },
      "region": {
        "name": "region",
        "type": "bytes32",
        "primary": true
      },
      "code2": {
        "name": "code2",
        "type": "bytes2",
        "bytesToString": true
      },
      "code3": {
        "name": "code3",
        "type": "bytes3",
        "bytesToString": true
      },
      "name": {
        "name": "name",
        "type": "string"
      }
    }
  },
  {
    "TableName": "CURRENCIES",
    "Filter": "Log1Text = 'AN://standards/currencies'",
    "Columns": {
      "alpha3": {
        "name": "alpha3",
        "type": "bytes3",
        "primary": true,
        "bytesToString": true
      },
      "m49": {
        "name": "m49",
        "type": "bytes3",
        "bytesToString": true
      },
      "name": {
        "name": "name",
        "type": "string"
      }
    }
  },
  {
    "TableName": "PARAMETER_TYPES",
    "Filter": "Log1Text = 'AN://agreements/parameter-types'",
    "Columns": {
      "parameter_type": {
        "name": "parameter_type",
        "type": "uint",
        "primary": true
      },
      "label": {
        "name": "label",
        "type": "bytes32",
        "bytesToString": true
      }
    }
  },
  {
    "TableName": "USER_ACCOUNTS",
    "Filter": "Log1Text = 'AN://user-accounts'",
    "Columns": {
      "user_account_address": {
        "name": "user_account_address",
        "type": "address",
        "primary": true
      },
      "id": {
        "name": "id",
        "type": "bytes32"
      },
      "owner": {
        "name": "owner",
        "type": "address"
      }
    }
  },
  {
    "TableName": "ORGANIZATION_ACCOUNTS",
    "Filter": "Log1Text = 'AN://organization-accounts'",
    "Columns": {
      "organization_address": {
        "name": "organization_address",
        "type": "address",
        "primary": true
      },
      "approver_count": {
        "name": "approver_count",
        "type": "uint"
      },
      "organization_id": {
        "name": "organization_id",
        "type": "bytes32"
      }
    }
  },
  {
    "TableName": "ORGANIZATION_APPROVERS",
    "Filter": "Log1Text = 'AN://organizations/approvers'",
    "Columns": {
      "organization_address": {
        "name": "organization_address",
        "type": "address",
        "primary": true
      },
      "approver_address": {
        "name": "approver_address",
        "type": "address",
        "primary": true
      }
    }
  },
  {
    "TableName": "ORGANIZATION_USERS",
    "Filter": "Log1Text = 'AN://organizations/users'",
    "DeleteFilter": "CRUD_ACTION = 'delete'",
    "Columns": {
      "organization_address": {
        "name": "organization_address",
        "type": "address",
        "primary": true
      },
      "user_address": {
        "name": "user_address",
        "type": "address",
        "primary": true
      }
    }
  },
  {
    "TableName": "ORGANIZATION_DEPARTMENTS",
    "Filter": "Log1Text = 'AN://organizations/departments'",
    "DeleteFilter": "CRUD_ACTION = 'delete'",
    "Columns": {
      "organization_address": {
        "name": "organization_address",
        "type": "address",
        "primary": true
      },
      "department_id": {
        "name": "department_id",
        "type": "bytes32",
        "bytesToString": true,
        "primary": true
      },
      "user_count": {
        "name": "user_count",
        "type": "uint"
      },
      "name": {
        "name": "name",
        "type": "string"
      }
    }
  },
  {
    "TableName": "DEPARTMENT_USERS",
    "Filter": "Log1Text = 'AN://departments/users'",
    "DeleteFilter": "CRUD_ACTION = 'delete'",
    "Columns": {
      "organization_address": {
        "name": "organization_address",
        "type": "address",
        "primary": true
      },
      "department_id": {
        "name": "department_id",
        "type": "bytes32",
        "bytesToString": true,
        "primary": true
      },
      "user_address": {
        "name": "user_address",
        "type": "address",
        "primary": true
      }
    }
  },
  {
    "TableName": "MEAN_TEMPERATURES",
    "Filter": "Log1Text = 'AN://oracles/wolfram/mean-temp'",
    "Columns": {
      "uuid": {
        "name": "uuid",
        "type": "bytes32",
        "primary": true
      },
      "location": {
        "name": "location",
        "type": "string"
      },
      "mean_temperature_start": {
        "name": "mean_temperature_start",
        "type": "uint"
      },
      "mean_temperature_end": {
        "name": "mean_temperature_end",
        "type": "uint"
      },
      "result_temperature": {
        "name": "result_temperature",
        "type": "string"
      }
    }
  }
]