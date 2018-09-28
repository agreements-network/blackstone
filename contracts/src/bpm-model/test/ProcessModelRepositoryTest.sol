pragma solidity ^0.4.23;

import "commons-base/BaseErrors.sol";
import "commons-base/Owned.sol";
import "commons-management/AbstractDbUpgradeable.sol";

import "bpm-model/DefaultProcessModelRepository.sol";
import "bpm-model/ProcessModelRepositoryDb.sol";
import "bpm-model/DefaultProcessModel.sol";

contract ProcessModelRepositoryTest {
	
	ProcessModelRepositoryDb db = new ProcessModelRepositoryDb();
	ProcessModelRepository repo = new DefaultProcessModelRepository();

	address author = 0x9d7fDE63776AaB9E234d656E654ED9876574C54C;
	uint error;
	bytes32 EMPTY = "";
	
	function testRepository() external returns (string) {

		SystemOwned(db).transferSystemOwnership(repo);
		AbstractDbUpgradeable(repo).acceptDatabase(db);
		
		ProcessModel pm1 = new DefaultProcessModel("testModel", "Test Model", [1,0,0], author, false, EMPTY, EMPTY);
		ProcessModel pm2 = new DefaultProcessModel("testModel", "Test Model", [2,0,0], author, false, EMPTY, EMPTY);
		ProcessModel pm3 = new DefaultProcessModel("testModel", "Test Model", [3,0,0], author, false, EMPTY, EMPTY);
		
		error = repo.addModel(pm1);
		if (error != BaseErrors.NO_ERROR()) return "Adding model 1 failed.";
		
		if (repo.getModel("testModel") != address(pm1)) return "Version 1.0.0 should be the active one.";

		error = repo.addModel(pm3);
		if (error != BaseErrors.NO_ERROR()) return "Adding model 3 failed.";
		
		error = repo.addModel(pm2);
		if (error != BaseErrors.NO_ERROR()) return "Adding model 2 failed.";

		error = repo.activateModel(pm2);
		if (error != BaseErrors.NO_ERROR()) return "Error activating model 2."; 
		
		if (repo.getModel("testModel") != address(pm2)) return "Version 2.0.0 should be the active one.";
		
		error = repo.activateModel(pm3);
		if (error != BaseErrors.NO_ERROR()) return "Error activating model 3."; 

		if (repo.getModel("testModel") != address(pm3)) return "Version 3.0.0 should be the active one.";
				
		return "success";
	}
}