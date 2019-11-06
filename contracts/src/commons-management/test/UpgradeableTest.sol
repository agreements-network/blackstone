pragma solidity ^0.5;

import "commons-management/AbstractUpgradeable.sol";
import "commons-management/AbstractVersionedArtifact.sol";

contract UpgradeableTest {

    function testUpgrade() external returns (string memory) {
        UpgradeDummy v100 = new UpgradeDummy("a", 11, 1, 0, 0);
        UpgradeDummy v110 = new UpgradeDummy("b", 12, 1, 1, 0);
        UpgradeDummy v227 = new UpgradeDummy("c", 13, 2, 2, 7);

        bool success;
        (success, ) = address(v110).call(abi.encodeWithSignature("upgrade(address)", address(v100)));
        if (success) return "Upgrading to a lower version should revert";
        if (v110.state() != "b" || v110.num() != 12 || v100.state() != "a" || v100.num() != 11) { return "v1.1.0 to v1.0.0 upgrade should not be successful!"; }
        v110.upgrade(address(v227));
        if (v110.state() != "b" || v110.num() != 12 || v227.state() != "b" || v227.num() != 12) { return "v1.1.0 to v2.2.7 upgrade failed!"; }
        v100.upgrade(address(v110));
        if (v100.state() != "a" || v100.num() != 11 || v110.state() != "a" || v110.num() != 11) { return "v1.0.0 to v1.1.0 upgrade failed!"; }
        return "success";
    }
}

contract UpgradeDummy is AbstractUpgradeable {

    bytes32 public state;
    uint public num;

    constructor(bytes32 _state, uint _num, uint8 maj, uint8 min, uint8 p) AbstractVersionedArtifact(maj, min, p) public {
        state = _state;
        num = _num;
    }

    function migrateTo(address addr) public returns (bool) {
        UpgradeDummy(addr).setNum(num);
        return true;
    }

    function migrateFrom(address addr) public returns (bool) {
        state = UpgradeDummy(addr).state();
        return true;
    }

    function setNum(uint _num) public {
        num = _num;
    }

}