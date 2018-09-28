pragma solidity ^0.4.23;

import "commons-base/BaseErrors.sol";

import "commons-standards/AbstractERC165.sol";
import "commons-standards/ERC165Utils.sol";

contract ERC165Test {

    bytes4 interfaceMyContract = bytes4(keccak256(abi.encodePacked("someFunction()"))) ^ bytes4(keccak256(abi.encodePacked("someOtherFunction(address)")));

    function testERC165() external returns (string) {

        address myImplAddress = new MyContract();

        // fail
        if (myImplAddress.call(bytes4(keccak256(abi.encodePacked("addIllegalSupport()")))))
            return "$1";
        if (ERC165Utils.implementsInterface(myImplAddress, bytes4(keccak256(abi.encodePacked("unknownFunction(bytes32)")))) == true)
            return "$1";

        // success
        if (ERC165Utils.implementsInterface(myImplAddress, 0x01ffc9a7) == false)
            return "Custom contract should support the ERC165 interface";
        if (ERC165Utils.implementsInterface(myImplAddress, interfaceMyContract) == false)
            return "Custom contract should support the custom interface";

        return "success";
    }

}

contract MyContract is AbstractERC165 {

    address addr;

    function someFunction() public pure {

    }

    function someOtherFunction(address _address) public {
        addr = _address;
    }

    constructor() public {
        addInterfaceSupport(this.someFunction.selector ^ this.someOtherFunction.selector);
    }

    function addIllegalSupport() public {
        addInterfaceSupport(0xffffffff);
    }
}