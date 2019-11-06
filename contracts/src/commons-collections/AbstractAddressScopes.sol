pragma solidity ^0.5;

import "commons-base/ErrorsLib.sol";
import "commons-collections/AbstractDataStorage.sol";
import "commons-collections/DataStorageUtils.sol";
import "commons-collections/AddressScopes.sol";

/**
 * @title AbstractAddressScopes
 * @dev Abstract implementation of the AddressScopes interface. This contract can be inherited from by any contract based on
 * DataStorage to add scopes to registered address values.
 */
contract AbstractAddressScopes is AddressScopes {

	using DataStorageUtils for DataStorageUtils.ConditionalData;

	struct AddressScope {
		address addr;
		bool exists;
		DataStorageUtils.DataScope scope;
	}

    /**
     * Stores data scopes for address/context combinations
     */
    mapping(bytes32 => AddressScope) addressScopes;

	/**
	 * Stores the address/context hash keys
	 */
	bytes32[] scopeKeys;

	/**
	 * @dev Internal constructor to enforce abstract contract.
	 */
	constructor() internal {}

	/**
	 * @dev Associates the given address with a scope qualifier for a given context.
	 * The context can be used to bind the same address to different scenarios and different scopes.
	 * The scope can either be represented by a fixed bytes32 value of by a ConditionalData that resolves to a bytes32 field.
	 * REVERTS if:
	 * - the given address is empty
	 * - neither the scope nor valid ConditionalData parameters are provided
	 * @param _address an address
	 * @param _context a context declaration binding the address to a scope
	 * @param _fixedScope a bytes32 representing a fixed scope
	 * @param _dataPath the dataPath of a ConditionalData defining the scope
	 * @param _dataStorageId the dataStorageId of a ConditionalData defining the scope
	 * @param _dataStorage the dataStorgage address of a ConditionalData defining the scope
	 */
	function setAddressScope(address _address, bytes32 _context, bytes32 _fixedScope, bytes32 _dataPath, bytes32 _dataStorageId, address _dataStorage)
		public
	{
		ErrorsLib.revertIf(_address == address(0),
			ErrorsLib.NULL_PARAMETER_NOT_ALLOWED(), "AbstractAddressScopes.setScope", "The address to which to add a scope must not be empty");
		ErrorsLib.revertIf(_fixedScope == "" && _dataPath == "",
			ErrorsLib.INVALID_INPUT(), "AbstractAddressScopes.setScope", "Fixed scope and ConditionalData must not both be empty");
		bytes32 key = keccak256(abi.encodePacked(_address, _context));
		if (!addressScopes[key].exists) {
			scopeKeys.push(key);
		}
		addressScopes[key].addr = _address;
		addressScopes[key].scope.context = _context;
		if (_fixedScope != "") {
            addressScopes[key].scope.fixedScope = _fixedScope;
        }
        else {
            addressScopes[key].scope.conditionalScope = DataStorageUtils.ConditionalData({dataPath: _dataPath, dataStorageId: _dataStorageId, dataStorage: _dataStorage, exists: true});
        }
		addressScopes[key].exists = true;
        emit LogEntityAddressScopeUpdate(
            EVENT_ID_ENTITIES_ADDRESS_SCOPES,
            address(this),
            _address,
            _context,
            _fixedScope,
            _dataPath,
            _dataStorageId,
            _dataStorage
        );        

	}

	/**
	 * @dev Returns the scope qualifier for the given address. If the scope depends on a ConditionalData, the function will attempt
	 * to resolve it using the provided DataStorage address.
	 * REVERTS if:
	 * - the scope is defined by a ConditionalData, but the DataStorage parameter is empty
	 * @param _address an address
	 * @param _context a context declaration binding the address to a scope
	 * @param _dataStorage a DataStorage contract to use as a basis if the scope is defined by a ConditionalData
	 * @return the scope qualifier or an empty bytes32, if no qualifier is set or cannot be determined
	 */
	function resolveAddressScope(address _address, bytes32 _context, DataStorage _dataStorage)
		external view
		returns (bytes32)
	{
		bytes32 key = keccak256(abi.encodePacked(_address, _context));
		if (addressScopes[key].scope.fixedScope != "") {
            return addressScopes[key].scope.fixedScope;
        }
        else if (addressScopes[key].scope.conditionalScope.exists) {
			// If the ConditionalData does not point to a DataStorage by address, the second function parameter (DataStorage) is required for resolution
			if (addressScopes[key].scope.conditionalScope.dataStorage == address(0)) {
				ErrorsLib.revertIf(address(_dataStorage) == address(0),
					ErrorsLib.INVALID_INPUT(), "AbstractAddressScopes.getScope", "The DataStorage parameter is required for a ConditionalData scope without a fixed dataStorage address");
			}
            (address targetDataStorage, bytes32 dataPath) = addressScopes[key].scope.conditionalScope.resolveDataLocation(_dataStorage);
			return DataStorage(targetDataStorage).getDataValueAsBytes32(dataPath);
        }
	}

	/**
	 * @dev Returns details about the configuration of the address scope.
	 * @param _address an address
	 * @param _context a context declaration binding the address to a scope
	 * @return fixedScope - a bytes32 representing a fixed scope
	 * @return dataPath - the dataPath of a ConditionalData defining the scope
	 * @return dataStorageId - the dataStorageId of a ConditionalData defining the scope
	 * @return dataStorage - the dataStorgage address of a ConditionalData defining the scope
	 */
	function getAddressScopeDetails(address _address, bytes32 _context)
		external view
		returns (bytes32 fixedScope, bytes32 dataPath, bytes32 dataStorageId, address dataStorage)
	{
		( , , fixedScope, dataPath, dataStorageId, dataStorage) = getAddressScopeDetailsForKey(keccak256(abi.encodePacked(_address, _context)));
	}

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
	function getAddressScopeDetailsForKey(bytes32 _key)
		public view
		returns (address keyAddress, bytes32 keyContext, bytes32 fixedScope, bytes32 dataPath, bytes32 dataStorageId, address dataStorage)
	{
		if (addressScopes[_key].exists) {
			keyAddress = addressScopes[_key].addr;
			keyContext = addressScopes[_key].scope.context;
			fixedScope = addressScopes[_key].scope.fixedScope;
			dataPath = addressScopes[_key].scope.conditionalScope.dataPath;
			dataStorageId = addressScopes[_key].scope.conditionalScope.dataStorageId;
			dataStorage = addressScopes[_key].scope.conditionalScope.dataStorage;
		}
	}

	/**
	 * @dev Returns the list of keys identifying the address/context scopes.
	 * @return the bytes32 scope keys
	 */
	function getAddressScopeKeys()
		external view
		returns (bytes32[] memory)
	{
		return scopeKeys;
	}

}