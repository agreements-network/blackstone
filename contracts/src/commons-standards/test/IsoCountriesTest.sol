pragma solidity ^0.5;

import "commons-collections/VersionLinkedAppendOnly.sol";

import "commons-standards/IsoCountries.sol";
import "commons-standards/IsoCountries100.sol";

contract TestCountries2 is IsoCountries {
  bytes2 public constant ABC = "AB";
	bytes2 public constant XYZ = "XY";
  constructor() VersionLinkedAppendOnly([2,0,0]) public {
    bytes32[] memory abcRegionKeys;
    // mapping(bytes32 => Region) abcRegions;
    bytes32[] memory xyzRegionsKeys;
    // mapping(bytes32 => Region) xyzRegions;
    countries[ABC] = IsoCountries.Country(ABC, "ABC", "123", "ABC Country", abcRegionKeys, true);
    countries[XYZ] = IsoCountries.Country(XYZ, "XYZ", "987", "XYZ Country", xyzRegionsKeys, true);
    countryKeys.push(ABC);
    countryKeys.push(XYZ);
  }

}

contract TestCountries3 is IsoCountries {
  bytes2 public constant MNO = "MN";
	bytes2 public constant PQR = "PQ";
  constructor() VersionLinkedAppendOnly([3,0,0]) public {
    bytes32[] memory mnoRegionKeys;
    // mapping(bytes32 => Region) mnoRegions;
    bytes32[] memory pqrRegionKeys;
    // mapping(bytes32 => Region) pqrRegions;
    countries[MNO] = IsoCountries.Country(MNO, "MNO", "456", "MNO Country", mnoRegionKeys, true);
    countries[PQR] = IsoCountries.Country(PQR, "PQR", "321", "PQR Country", pqrRegionKeys, true);
    countryKeys.push(MNO);
    countryKeys.push(PQR);
  }

}

contract IsoCountriesTest {
  
  bytes2 USA = "US";
  bytes32 USA_NY = keccak256(abi.encodePacked(USA, "NY"));

  function testIsoCountries() external returns (string memory) {

    IsoCountries100 c100 = new IsoCountries100();
    TestCountries2 c200 = new TestCountries2();
    TestCountries3 c300 = new TestCountries3();

    c100.appendNewVersion(c200);
    c200.appendNewVersion(c300);

    // versioning tests
    if (c100.getLatest() != address(c300)) { return "c100.latest does not point to c300"; }
    if (c100.getSuccessor() != address(c200)) { return "c100.successor does not point to c200"; }
    if (c200.getLatest() != address(c300)) { return "c200.latest does not point to c300"; }
    if (c200.getPredecessor() != address(c100)) { return "c200.predecessor does not point to c100"; }
    if (c200.getSuccessor() != address(c300)) { return "c100.successor does not point to c200"; }
    if (c300.getPredecessor() != address(c200)) { return "c300.predecessor does not point to c200"; }
    if (c300.getLatest() != address(c300)) { return "c300.latest does not point to c300"; }

    // standards tests
    if (c100.getNumberOfCountries() != uint(246)) { return "Unexpected country count"; }
    if (c100.getCountryAtIndex(232) != bytes2("US")) { return "Unexpected country found at index 0"; }
    if (c100.getCountryAtIndex(40) != bytes2("CA")) { return "Unexpected country found at index 1"; }    
    if (c100.getNumberOfRegions(bytes2("US")) != 57) return "Unexpected number of regions found for US";
    
    bytes32 nyRegionKey = c100.getRegionAtIndex(USA, 31);
    if (nyRegionKey != USA_NY) return "Unexpected region key found for USA_NY";
    if (!c100.isCountry("CA")) { return "Expected to find CA as an existing country"; }
    if (!c100.isRegion("US", "NY", "")) { return "Expected to find US-NY as an existing region"; }

    if (IsoCountries(c100.getSuccessor()).isCountry("US")) { return "c200 should not have US"; }
    if (IsoCountries(c100.getLatest()).isCountry("US")) { return "c300 should not have US"; }
    if (!IsoCountries(c100.getSuccessor()).isCountry("XY")) { return "c200 should have XY"; }
    if (!IsoCountries(c100.getLatest()).isCountry("MN")) { return "c300 should have MN"; }

    return "success";
  }
}