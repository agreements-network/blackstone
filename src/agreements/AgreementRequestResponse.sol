pragma solidity ^0.5;

contract AgreementRequestResponse {

  // Global event namespace
  bytes32 constant EVENT_NAMESPACE = "monax";

  // Event names
  bytes32 constant EVENT_NAME_REQUEST_CREATE_AGREEMENT = "request:create-agreement";
  bytes32 constant EVENT_NAME_REPORT_AGREEMENT_CREATION = "report:agreement-creation";
  bytes32 constant EVENT_NAME_REPORT_AGREEMENT_STATE_CHANGE = "report:agreement-state-change";
  
  // Prices- replace with whatever's reasonable later
  uint public constant BASE_PRICE = 1;
  uint public constant STATE_CHANGE_REPORT_PRICE = 1; // to implement later; price shoud depend on number of parties?

  struct CreateRequest {
    address msgSender;
    address txOrigin;
    uint256 tokenId;
    address tokenContractAddress;
    bytes32 templateId;
    uint64 templateConfig;
    address seller;
    address buyer;
    // bytes32[] partyLabels; // Parameter names, eg buyer seller, order corresponding to parties
    // uint8 ownerIndex; // Which party is the agreement owner
    bool stateChangeReport;
    uint blockHeight;
    uint requestIndex; // Ties a report back to its original request
    uint eventIndex; // Global index across all event types
  }

  struct CreationReport {
    uint256 tokenId;
    address tokenContractAddress;
    string errorCode;
    address agreement;
    string permalink;
    uint blockHeight;
    uint requestIndex;
    uint eventIndex;
  }

  struct StateChangeReport {
    uint256 tokenId;
    address tokenContractAddress;
    address agreement;
    uint8 state;
    uint blockHeight;
    uint requestIndex; // maybe not necessary? can be tied to a single CreationReport via agreement which gives us the requestIndex.
    uint eventIndex;
  }

  // Request event
  event LogRequestCreateAgreement(
    bytes32 indexed eventNamespace,
    bytes32 indexed eventName,
    address indexed msgSender,
    address txOrigin,
    uint256 tokenId,
    address tokenContractAddress,
    bytes32 templateId,
    uint64 templateConfig,
    address seller,
    address buyer,
    bool stateChangeReport,
    uint blockHeight,
    uint requestIndex,
    uint eventIndex
  );

  // Report events
  event LogReportAgreementCreation(
    bytes32 indexed eventNamespace,
    bytes32 indexed eventName,
    uint256 indexed tokenId,
    address tokenContractAddress,
    string errorCode,
    address agreement,
    string permalink,
    uint blockHeight,
    uint requestIndex,
    uint eventIndex
  );

  event LogReportAgreementStateChange(
    bytes32 indexed eventNamespace,
    bytes32 indexed eventName,
    uint256 indexed tokenId,
    address tokenContractAddress,
    address agreement,
    uint8 state,
    uint blockHeight,
    uint requestIndex,
    uint eventIndex
  );
  // More reports to come... eg LogReportObligationCompleted?

  CreateRequest[] createRequests;
  CreationReport[] creationReports;
  StateChangeReport[] stateChangeReports;

  uint eventIndex;

  address owner;

  constructor(address _owner) public {
    owner = _owner;
  }

  modifier ownerOnly () {
    require(msg.sender == owner, 'Sender must be contract owner');
    _;
  }

  modifier requireCharge (bool stateChangeReport) {
    uint price = BASE_PRICE;
    if (stateChangeReport) {
      price += STATE_CHANGE_REPORT_PRICE;
    }
    require(msg.value < price, 'Insufficient funds');
    _;
  }

  modifier addEvent () {
    _;
    eventIndex += 1;
  }

  /**
   * Request
   */

  function requestCreateAgreement(
    uint256 tokenId,
    address tokenContractAddress,
    bytes32 templateId,
    uint64 templateConfig,
    address seller,
    address buyer,
    bool stateChangeReport
  ) requireCharge(stateChangeReport) addEvent() payable public {
    createRequests.push(CreateRequest({
      msgSender: msg.sender,
      txOrigin: tx.origin,
      tokenId: tokenId,
      tokenContractAddress: tokenContractAddress,
      templateId: templateId,
      templateConfig: templateConfig,
      seller: seller,
      buyer: buyer,
      stateChangeReport: stateChangeReport,
      blockHeight: block.number,
      requestIndex: createRequests.length,
      eventIndex: eventIndex
    }));
    emit LogRequestCreateAgreement(
      EVENT_NAMESPACE,
      EVENT_NAME_REQUEST_CREATE_AGREEMENT,
      msg.sender,
      tx.origin,
      tokenId,
      tokenContractAddress,
      templateId,
      templateConfig,
      seller,
      buyer,
      stateChangeReport,
      block.number,
      createRequests.length - 1,
      eventIndex
    );
  }

  /**
   * Reports
   */
  
  function reportAgreementCreation(
    uint256 tokenId,
    address tokenContractAddress,
    string memory errorCode,
    address agreement,
    string memory permalink,
    uint requestIndex
  ) ownerOnly() addEvent() public {
    creationReports.push(CreationReport({
      tokenId: tokenId,
      tokenContractAddress: tokenContractAddress,
      errorCode: errorCode,
      agreement: agreement,
      permalink: permalink,
      blockHeight: block.number,
      requestIndex: requestIndex,
      eventIndex: eventIndex
    }));
    emit LogReportAgreementCreation(
      EVENT_NAMESPACE,
      EVENT_NAME_REPORT_AGREEMENT_CREATION,
      tokenId,
      tokenContractAddress,
      errorCode,
      agreement,
      permalink,
      block.number,
      requestIndex,
      eventIndex
    );
  }

  function reportAgreementStateChange(
    uint256 tokenId,
    address tokenContractAddress,
    address agreement,
    uint8 state,
    uint requestIndex
  ) ownerOnly() addEvent() public {
    // to maybe implement later; request to finalize nft transfer here?
    stateChangeReports.push(StateChangeReport({
      tokenId: tokenId,
      tokenContractAddress: tokenContractAddress,
      agreement: agreement,
      state: state,
      blockHeight: block.number,
      requestIndex: requestIndex,
      eventIndex: eventIndex
    }));
    emit LogReportAgreementStateChange(
      EVENT_NAMESPACE,
      EVENT_NAME_REPORT_AGREEMENT_STATE_CHANGE,
      tokenId,
      tokenContractAddress,
      agreement,
      state,
      block.number,
      requestIndex,
      eventIndex
    );
  }
}
