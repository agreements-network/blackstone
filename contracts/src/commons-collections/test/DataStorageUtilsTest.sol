pragma solidity ^0.5;

import "commons-collections/DataStorage.sol";
import "commons-collections/FullDataStorage.sol";
import "commons-collections/DataStorageUtils.sol";

contract DataStorageUtilsTest {
	
	using DataStorageUtils for DataStorageUtils.ConditionalData;

	string SUCCESS = "success";
	bytes32 EMPTY = "";
	
	// Storage contracts used in tests
	DataStorage myStorage;
	DataStorage mySubDataStorage;
	ResolverHelper helper = new ResolverHelper();
	DataStorageUtils.ConditionalData conditionalData;	
	
	uint error;

	function testConditionalDataHandling() external returns (string memory) {
		
		address addr;
		bytes32 path;
		bool success;

		myStorage = new FullDataStorage();
		mySubDataStorage = new FullDataStorage();

		myStorage.setDataValueAsAddress("subStorage", address(mySubDataStorage));
		mySubDataStorage.setDataValueAsUint("key1", 99);

		// test resolveDataStorageAddress
		addr = DataStorageUtils.resolveDataStorageAddress("subStorage", address(0), myStorage);
		if (addr != address(mySubDataStorage)) return "address resolution for dataStorageId should retrieve mySubDataStorage address";
		addr = DataStorageUtils.resolveDataStorageAddress(EMPTY, address(0), myStorage);
		if (addr != address(myStorage)) return "address resolution for empty dataStorageId should retrieve myStorage address";
		addr = DataStorageUtils.resolveDataStorageAddress(EMPTY, address(this), mySubDataStorage);
		if (addr != address(this)) return "address resolution using an explicit address should return that address";
		addr = DataStorageUtils.resolveDataStorageAddress("fakePath", address(0), myStorage);
		if (addr != address(0)) return "address resolution for non-existent dataStorageId should retrieve 0x0 address";
		// test reverts
		(success, ) = address(helper).call(abi.encodeWithSignature("resolveDataStorageAddress(bytes32,address,address)", bytes32("subStorage"), address(0), address(0)));
		if (success)
			return "Address resolution with a dataStorageId and an empty DataStorage should revert";

		conditionalData = DataStorageUtils.ConditionalData({dataPath: "key1", dataStorageId: "subStorage", dataStorage: address(0), exists: true});
		(addr, path) = conditionalData.resolveDataLocation(myStorage);
		if (addr != address(mySubDataStorage)) return "location for conditionalData should retrieve mySubDataStorage address";
		if (path != "key1") return "location for conditionalData should retrieve key1 dataPath";
		// test reverts
		(success, ) = address(helper).call(abi.encodeWithSignature("resolveDataLocation(bytes32,bytes32,address,address)", bytes32("key1"), bytes32("bogusStoriddgeID"), address(0), address(myStorage)));
		if (success)
			return "Location resolution with non-existent dataStorageId should revert";

		return SUCCESS;
	}

}

/**
 * @dev Helper contract to wrap the library functions and make them .call() -able
 */
contract ResolverHelper {

	DataStorageUtils.ConditionalData conditionalData;	

	function resolveDataStorageAddress(bytes32 _dataStorageId, address _dataStorageAddress, DataStorage _refDataStorage) public view returns (address) {
		return DataStorageUtils.resolveDataStorageAddress(_dataStorageId, _dataStorageAddress, _refDataStorage);
	}

  	function resolveDataLocation(bytes32 _dataPath, bytes32 _dataStorageId, address _dataStorage, address _refDataStorage)
		public
    	returns (address dataStorage, bytes32 dataPath)
	{
		conditionalData = DataStorageUtils.ConditionalData({dataPath: _dataPath, dataStorageId: _dataStorageId, dataStorage: _dataStorage, exists: true});
		return DataStorageUtils.resolveDataLocation(conditionalData, DataStorage(_refDataStorage));
	}

}
