pragma solidity ^0.5;

import "commons-collections/DataStorage.sol";

/**
 * @title AddressScopes Interface
 * @dev API for a contract that manages associations of scope definitions to addresses. This contract
 * is meant to be used in conjunction with DataStorage contracts since conditional scopes can be resolved at runtime with the help of a DataStorage.
 */
contract AddressScopes {

	event LogEntityAddressScopeUpdate(
		bytes32 indexed eventId,
		address entityAddress,
		address scopeAddress,
		bytes32 scopeContext,
		bytes32 fixedScope,
		bytes32 dataPath,
		bytes32 dataStorageId,
		address dataStorage
	);

	bytes32 public constant EVENT_ID_ENTITIES_ADDRESS_SCOPES = "AN://entities/address-scopes";

  // The ERC165 ID only comprises the core Address Scopes functions
	bytes4 public constant ERC165_ID_Address_Scopes = bytes4(keccak256(abi.encodePacked("setAddressScope(address,bytes32,bytes32,bytes32,bytes32,address)"))) ^
													bytes4(keccak256(abi.encodePacked("resolveAddressScope(address,bytes32,address)"))) ^
													bytes4(keccak256(abi.encodePacked("getAddressScopeDetails(address,bytes32)"))) ^
													bytes4(keccak256(abi.encodePacked("getAddressScopeDetailsForKey(bytes32)"))) ^
													bytes4(keccak256(abi.encodePacked("getAddressScopeKeys()")));

	/**
	 * @dev Associates the given address with a scope qualifier for a given context.
	 * The context can be used to bind the same address to different scenarios and different scopes.
	 * The scope can either be represented by a fixed bytes32 value of by a ConditionalData that resolves to a bytes32 field.
	 * @param _address an address
	 * @param _context a context declaration binding the address to a scope
	 * @param _fixedScope a bytes32 representing a fixed scope
	 * @param _dataPath the dataPath of a ConditionalData defining the scope
	 * @param _dataStorageId the dataStorageId of a ConditionalData defining the scope
	 * @param _dataStorage the dataStorgage address of a ConditionalData defining the scope
	 */
	function setAddressScope(address _address, bytes32 _context, bytes32 _fixedScope, bytes32 _dataPath, bytes32 _dataStorageId, address _dataStorage) public;

	/**
	 * @dev Returns the scope for the given address and context. If the scope depends on a ConditionalData, the function should attempt
	 * to resolve it and return the result.
	 * @param _address an address
	 * @param _context a context declaration binding the address to a scope
	 * @param _dataStorage a DataStorage contract to use as a basis if the scope is defined by a ConditionalData
	 * @return the scope qualifier or an empty bytes32, if no qualifier is set or cannot be determined
	 */
	function resolveAddressScope(address _address, bytes32 _context, DataStorage _dataStorage) external view returns (bytes32);

	/**
	 * @dev Returns details about the configuration of the address scope.
	 * @param _address an address
	 * @param _context a context declaration binding the address to a scope
	 * @return fixedScope - a bytes32 representing a fixed scope
	 * @return dataPath - the dataPath of a ConditionalData defining the scope
	 * @return dataStorageId - the dataStorageId of a ConditionalData defining the scope
	 * @return dataStorage - the dataStorgage address of a ConditionalData defining the scope
	 */
	function getAddressScopeDetails(address _address, bytes32 _context) external view returns (bytes32 fixedScope, bytes32 dataPath, bytes32 dataStorageId, address dataStorage);

	/**
	 * @dev Returns details about the configuration of the address scope.
	 * @param _key a scope key
	 * @return keyAddress - the address encoded in the key
	 * @return keyContext - the context encoded in the key
	 * @return fixedScope - a bytes32 representing a fixed scope
	 * @return dataPath - the dataPath of a ConditionalData defining the scope
	 * @return dataStorageId - the dataStorageId of a ConditionalData defining the scope
	 * @return dataStorage - the dataStorgage address of a ConditionalData defining the scope
	 */
	function getAddressScopeDetailsForKey(bytes32 _key) public view returns (address keyAddress, bytes32 keyContext, bytes32 fixedScope, bytes32 dataPath, bytes32 dataStorageId, address dataStorage);

	/**
	 * @dev Returns the list of keys identifying the address/context scopes.
	 * @return the bytes32 scope keys
	 */
	function getAddressScopeKeys() external view returns (bytes32[] memory);
}