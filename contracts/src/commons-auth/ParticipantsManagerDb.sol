pragma solidity ^0.5;

import "commons-base/BaseErrors.sol";
import "commons-base/SystemOwned.sol";
import "commons-utils/ArrayUtilsLib.sol";
import "commons-collections/Mappings.sol";
import "commons-collections/MappingsLib.sol";

/**
 * @title ParticipantsManagerDb
 * @dev Stores and manages UserAccount and Organization entities.
 */
contract ParticipantsManagerDb is SystemOwned {
  
  using MappingsLib for Mappings.AddressBoolMap;

  Mappings.AddressBoolMap userAccounts;
  Mappings.AddressBoolMap organizations;

  /**
   * @dev Creates a new ParticipantsManagerDb and registers the msg.sender as the systemOwner.
   */
  constructor() public {
    systemOwner = msg.sender;
  }
 
  function addUserAccount(address _account) external pre_onlyBySystemOwner returns (uint error) {
    error = userAccounts.insert(_account, true);
  }

  function userAccountExists(address _account) external view returns (bool) {
    return userAccounts.exists(_account);
  }

  function getNumberOfUserAccounts() external view returns (uint) {
    return userAccounts.keys.length;
  }

  function getUserAccount(address _account) external view returns (bool) {
    return userAccounts.get(_account);
  }

  function getUserAccountAtIndex(uint _index) external view returns (address) {
    ( , address account) = userAccounts.keyAtIndex(_index);
    return account;
  }

  function addOrganization(address _address) external pre_onlyBySystemOwner returns (uint error) {
    error = organizations.insert(_address, true);
  }

  function organizationExists(address _address) external view returns (bool) {
    return organizations.exists(_address);
  }

  function getNumberOfOrganizations() external view returns (uint) {
    return organizations.keys.length;
  }

  function getOrganizationAtIndex(uint _index) external view returns (address) {
    ( , address key) = organizations.keyAtIndex(_index);
    return key;
  } 
  
}
