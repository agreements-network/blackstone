pragma solidity ^0.5;

import "commons-management/AbstractUpgradeable.sol";
import "commons-management/ArtifactsFinderEnabled.sol";

contract TestService is AbstractUpgradeable, ArtifactsFinderEnabled {

    bytes32 public name;
    uint16 public status;
    string public dependencyKey;
    address public dependencyService;

    constructor(uint8[3] memory _v, string memory _depKey) public AbstractVersionedArtifact(_v[0],_v[1],_v[2]) {
        dependencyKey = _depKey;
    }

    function setName(bytes32 _name) public {
        name = _name;
    }

    function setStatus(uint16 _status) public {
        status = _status;
    }

    function refreshDependencies() public {
        if (bytes(dependencyKey).length > 0) {
            (dependencyService, ) = ArtifactsFinder(artifactsFinder).getArtifact(dependencyKey);
            require(dependencyService != address(0), "dependency not found");
        }
    }

    function setArtifactsFinder(address _finder) public {
        super.setArtifactsFinder(_finder);
        refreshDependencies();
    }

    function migrateFrom(address) public returns (bool success) {
        success = true;
    }

    function migrateTo(address) public returns (bool success) {
        success = true;
    }
}