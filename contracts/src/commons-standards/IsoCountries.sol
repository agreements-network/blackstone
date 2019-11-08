pragma solidity ^0.5;

import "commons-collections/VersionLinkedAppendOnly.sol";

contract IsoCountries is VersionLinkedAppendOnly {

	event LogCountryRegistration(
		bytes32 indexed eventId,
		bytes2 alpha2,
		bytes3 alpha3,
		bytes3 m49,
		string name
	);

	event LogRegionRegistration(
		bytes32 indexed eventId,
		bytes2 country,
		bytes32 region,
		bytes2 code2,
		bytes3 code3,
		string name
	);

	bytes32 public constant EVENT_ID_ISO_COUNTRIES = "AN://standards/countries";
	bytes32 public constant EVENT_ID_ISO_REGIONS = "AN://standards/regions";

  // Struct representing ISO 3166-1 Country Codes
	struct Country {			
		bytes2 alpha2;												// 2-letter country code
		bytes3 alpha3; 												// 3-letter country code
		bytes3 m49; 													// 3-digit numeric code
		string name;													// Short country name (EN)
		bytes32[] regionKeys;									// regionKeys
		mapping(bytes32 => Region) regions;		// regions
		bool exists;	
	}

	// Struct representing ISO 3166-2 Region Codes
	struct Region {
		bytes2 country; 											// Part1 matching the country's alpha2 code
		bytes2 code2; 												// Part2 2-character region code where used
		bytes3 code3;													// Part2 3-character region code where used
		string name; 													// Region name (EN)
		bool exists;
	}

	bytes2[] countryKeys;
	mapping(bytes2 => Country) public countries;

  function getNumberOfCountries() external view returns (uint size) {
		return countryKeys.length;
	}

	function getCountryAtIndex(uint _index) external view returns (bytes2 alpha2) {
		return countryKeys[_index];
	}

	function getCountryData(bytes2 _key) external view returns (bytes2 alpha2, bytes3 alpha3, bytes3 m49, string memory name) {
		alpha2 = countries[_key].alpha2;
		alpha3 = countries[_key].alpha3;
		m49 = countries[_key].m49;
		name = countries[_key].name;
	}

	function isCountry(bytes2 _country) external view returns (bool) {
		return countries[_country].exists;
	}

	function getNumberOfRegions(bytes2 _country) external view returns (uint size) {
		return countries[_country].regionKeys.length;
	}

	function getRegionAtIndex(bytes2 _country, uint _index) external view returns (bytes32 key) {
		return countries[_country].regionKeys[_index];
	}

	function getRegionData(bytes2 _country, bytes32 _key) external view returns (bytes2 alpha2, bytes2 code2, bytes3 code3, string memory name) {
		alpha2 = countries[_country].regions[_key].country;
		code2 = countries[_country].regions[_key].code2;
		code3 = countries[_country].regions[_key].code3;
		name = countries[_country].regions[_key].name;
	}

	function isRegion(bytes2 _country, bytes2 _code2, bytes3 _code3) external view returns (bool) {
		if (countries[_country].exists) {
			bytes32 regionKey2 = keccak256(abi.encodePacked(_country, _code2));
			bytes32 regionKey3 = keccak256(abi.encodePacked(_country, _code3));
			if (countries[_country].regions[regionKey2].exists || countries[_country].regions[regionKey3].exists) {
				return true;
			}
		}
		return false;
	}
    
}