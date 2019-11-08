pragma solidity ^0.5;

import "commons-collections/VersionLinkedAppendOnly.sol";

import "commons-standards/IsoCurrencies.sol";
import "commons-standards/IsoCurrencies100.sol";

contract TestCurrencies2 is IsoCurrencies {
  bytes3 constant public KLM = "KLM";
	bytes3 constant public IOU = "IOU";

  constructor() VersionLinkedAppendOnly([2,0,0]) public {
    currencies[KLM] = Currency(KLM, "456", "KLM currency", true);
		currencies[IOU] = Currency(IOU, "123", "IOU currency", true);
    currencyKeys.push(KLM);
    currencyKeys.push(IOU);    
  }
}

contract TestCurrencies3 is IsoCurrencies {
  bytes3 constant public FOO = "FOO";
	bytes3 constant public BAR = "BAR";

  constructor() VersionLinkedAppendOnly([3,0,0]) public {
    currencies[FOO] = Currency(FOO, "935", "FOO currency", true);
		currencies[BAR] = Currency(BAR, "028", "BAR currency", true);
    currencyKeys.push(FOO);
    currencyKeys.push(BAR);    
  }
}

contract IsoCurrenciesTest {

  function testIsoCurrencies() external returns (string memory) {

    IsoCurrencies100 c100 = new IsoCurrencies100();
    TestCurrencies2 c200 = new TestCurrencies2();
    TestCurrencies3 c300 = new TestCurrencies3();

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

    // standard tests
    if (c100.getNumberOfCurrencies() != 178) { return "Unexpected currency count"; }
    if (c100.getCurrencyAtIndex(148) != "USD") { return "Unexpected currency found at index 148"; }
    if (c100.isCurrency("FOO")) { return "FOO should not be an existing curreny in c100"; } 
    if (!c100.isCurrency("AED")) { return "AED should be an existing curreny in c100"; }

    if (IsoCurrencies(c100.getSuccessor()).isCurrency("USD")) { return "c200 should not have USD"; }
    if (IsoCurrencies(c100.getLatest()).isCurrency("USD")) { return "c300 should not have USD"; }
    if (!IsoCurrencies(c100.getSuccessor()).isCurrency("IOU")) { return "c200 should have IOU"; }
    if (!IsoCurrencies(c100.getLatest()).isCurrency("FOO")) { return "c300 should have FOO"; }

    return "success";
  }
}