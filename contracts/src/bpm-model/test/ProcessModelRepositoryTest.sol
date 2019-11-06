pragma solidity ^0.5;

import "commons-base/BaseErrors.sol";
import "commons-base/Owned.sol";
import "commons-management/AbstractDbUpgradeable.sol";
import "commons-management/ArtifactsRegistry.sol";
import "commons-management/DefaultArtifactsRegistry.sol";

import "bpm-model/DefaultProcessModelRepository.sol";
import "bpm-model/ProcessModelRepositoryDb.sol";
import "bpm-model/DefaultProcessModel.sol";

contract ProcessModelRepositoryTest {
	
	address author = 0x9d7fDE63776AaB9E234d656E654ED9876574C54C;
	uint error;
	string dummyModelFileReference = "{json grant}";

    ArtifactsRegistry artifactsRegistry;
    DefaultProcessModel defaultProcessModelImpl = new DefaultProcessModel();

	constructor() public {
		artifactsRegistry = new DefaultArtifactsRegistry();
        DefaultArtifactsRegistry(address(artifactsRegistry)).initialize();
	}

    /**
     * @dev Internal helper function to initiate a new ParticipantsManager with an empty database.
     */
    function createNewProcessModelRepository() internal returns (ProcessModelRepository repository) {
		repository =  new DefaultProcessModelRepository();
        ArtifactsFinderEnabled(address(repository)).setArtifactsFinder(address(artifactsRegistry));
        artifactsRegistry.registerArtifact(repository.OBJECT_CLASS_PROCESS_MODEL(), address(defaultProcessModelImpl), defaultProcessModelImpl.getArtifactVersion(), true);
		ProcessModelRepositoryDb database = new ProcessModelRepositoryDb();
		SystemOwned(database).transferSystemOwnership(address(repository));
		AbstractDbUpgradeable(address(repository)).acceptDatabase(address(database));
	}

	function testRepository() external returns (string memory) {

		ProcessModelRepository repo = createNewProcessModelRepository();
		
		( ,address pm1) = repo.createProcessModel("testModel", [1,0,0], author, false, dummyModelFileReference);
		( ,address pm2) = repo.createProcessModel("testModel", [2,0,0], author, false, dummyModelFileReference);
		( ,address pm3) = repo.createProcessModel("testModel", [3,0,0], author, false, dummyModelFileReference);
				
		if (repo.getModel("testModel") != pm1) return "Version 1.0.0 should be the active one.";

		error = repo.activateModel(ProcessModel(pm2));
		if (error != BaseErrors.NO_ERROR()) return "Error activating model 2."; 
		if (repo.getModel("testModel") != pm2) return "Version 2.0.0 should be the active one.";
		
		error = repo.activateModel(ProcessModel(pm3));
		if (error != BaseErrors.NO_ERROR()) return "Error activating model 3."; 
		if (repo.getModel("testModel") != pm3) return "Version 3.0.0 should be the active one.";
				
		return "success";
	}
}