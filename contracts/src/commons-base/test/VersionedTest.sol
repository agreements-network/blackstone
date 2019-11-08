pragma solidity ^0.5;

import "commons-base/Versioned.sol";
import "commons-base/AbstractVersioned.sol";

contract VersionedTest {

    /**
     * @dev Tests the compare function of the Versioned contract
     */
    function testCompare() external returns (string memory) {

        // Test access functions
        VersionedContract sub = new VersionedContract([2,5,17]);
        if (sub.getVersion()[0] != 2) return "getVersion()[0] expected to be 2"; 
        if (sub.getVersion()[1] != 5) return "getVersion()[0] expected to be 5"; 
        if (sub.getVersion()[2] != 17) return "getVersion()[0] expected to be 17"; 
        if (sub.getVersionMajor() != 2) return "getVersionMajor() expected to be 2";
        if (sub.getVersionMinor() != 5) return "getVersionMinor() expected to be 5";
        if (sub.getVersionPatch() != 17) return "getVersionPatch() expected to be 17";

        // Test comparison
        Versioned v731 = new VersionedContract([7, 3, 1]);
        Versioned v731_2 = new VersionedContract([7, 3, 1]);
        Versioned v020 = new VersionedContract([0, 2, 0]);
        Versioned v240 = new VersionedContract([2, 4, 0]);

        if( v731.compareVersion(address(v731_2)) != 0 ) { return "Comparison (7.3.1 = 7.3.1) failed"; }
        if( v731.compareVersion(address(v240)) != -1 ) { return  "Comparison (7.3.1 > 2.4.0) failed"; }
        if( v731.compareVersion(address(v020)) != -1 ) { return  "Comparison (7.3.1 > 0.2.0) failed"; }
        if( v240.compareVersion(address(v020)) != -1 ) { return  "Comparison (2.4.0 > 0.2.0) failed"; }
        if( v020.compareVersion(address(v240)) != 1 ) { return  "Comparison (0.2.0 < 2.4.0) failed"; }
        if( v020.compareVersion(address(v731)) != 1 ) { return  "Comparison (0.2.0 < 7.3.1) failed"; }
        if( v240.compareVersion(address(v731)) != 1 ) { return  "Comparison (2.4.0 < 7.3.1) failed"; }
        
        return "success";
    }
}

contract VersionedContract is AbstractVersioned {

    constructor(uint8[3] memory _version) public {
        semanticVersion = _version;
    }
}