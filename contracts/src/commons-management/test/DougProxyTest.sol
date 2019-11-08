pragma solidity ^0.5;

import "commons-management/DOUG.sol";
import "commons-management/DefaultDoug.sol";
import "commons-management/DougProxy.sol";
import "commons-management/ArtifactsRegistry.sol";
import "commons-management/DefaultArtifactsRegistry.sol";

import "commons-management/test/TestService.sol";

contract DougProxyTest {

    string constant SUCCESS = "success";

    function testProxyDelegation() external returns (string memory) {

        ArtifactsRegistry artifactsRegistry = new DefaultArtifactsRegistry();
        DefaultArtifactsRegistry(address(artifactsRegistry)).initialize();

        DefaultDoug doug = new DefaultDoug();
        DougProxy proxy = new DougProxy(address(doug));
        if (proxy.getDelegate() != address(doug)) return "Doug should be set in the proxy";
        if (DefaultDoug(address(proxy)).getOwner() != doug.getOwner()) return "DougProxy and Doug should point to the same owner";
        if (DefaultDoug(address(proxy)).getOwner() != address(this)) return "The proxy owner should be set to this contract";

        artifactsRegistry.transferSystemOwnership(address(proxy));
        DefaultDoug(address(proxy)).setArtifactsRegistry(address(artifactsRegistry));
        if (doug.getArtifactsRegistry() != address(0)) return "DOUG's ArtifactsRegistry should be empty since it's the delegate target";
        if (DefaultDoug(address(proxy)).getArtifactsRegistry() != address(artifactsRegistry)) return "The proxy's ArtifactsRegistry should be set";

        uint currentSize = artifactsRegistry.getNumberOfArtifacts();
        DOUG(address(proxy)).deploy("agreements-network/libraries/BaseErrors", address(this));
        if (artifactsRegistry.getNumberOfArtifacts() != currentSize+1) return "ArtifactsRegistry size should be +1 after adding library via DOUG proxy";
        
        TestService s1 = new TestService([1,0,0], "");
        s1.transferUpgradeOwnership(address(proxy));
        DOUG(address(proxy)).deploy("agreements-network/services/ProxyDelegateTest1", address(s1));
        if (artifactsRegistry.getNumberOfArtifacts() != currentSize+2) return "ArtifactsRegistry size should be +2 after adding service via DOUG proxy";
        if (DOUG(address(proxy)).lookup("agreements-network/services/ProxyDelegateTest1") != address(s1)) return "service should be retrievable via the DOUG proxy";

        // TODO test upgrades of Doug and ArtifactsRegistry itself
        
        return SUCCESS;
    }

}

