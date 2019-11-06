pragma solidity ^0.5;

import "commons-base/SystemOwned.sol";
import "commons-base/BaseErrors.sol";
import "commons-collections/Mappings.sol";
import "commons-collections/MappingsLib.sol";
import "commons-utils/ArrayUtilsLib.sol";

contract ProcessModelRepositoryDb is SystemOwned {
  
  using MappingsLib for Mappings.Bytes32AddressMap;
  using ArrayUtilsLib for address[];

  mapping(bytes32 => Mappings.Bytes32AddressMap) models;
	address[] public modelAddresses;
	Mappings.Bytes32AddressMap activeModels;

  constructor() public {
    systemOwner = msg.sender;
  }

  function addModel(bytes32 _id, uint8[3] calldata _version, address _address) external pre_onlyBySystemOwner returns (uint error) {
    error = models[_id].insert(keccak256(abi.encodePacked(_version)), _address);
    if (error == BaseErrors.NO_ERROR()) {
      modelAddresses.push(_address);
    }
  }

  function getModel(bytes32 _id, uint8[3] calldata _version) external view returns (address) {
    return models[_id].get(keccak256(abi.encodePacked(_version)));
  }

  function getNumberOfModels() external view returns (uint size) {
    return modelAddresses.length;
  }

  function getModelAtIndex(uint _idx) external view returns (address) {
		return modelAddresses[_idx];
	}

  function registerActiveModel(bytes32 _id, address _model) external pre_onlyBySystemOwner {
    activeModels.insertOrUpdate(_id, _model);
  }

  function modelIsRegistered(address _model) external view returns (bool) {
    return modelAddresses.contains(_model);
  }

  function modelIsActive(bytes32 _id) external view returns (bool) {
    return activeModels.exists(_id);
  }

  function getActiveModel(bytes32 _id) external view returns (address) {
    return activeModels.get(_id);
  }

}