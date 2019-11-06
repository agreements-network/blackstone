pragma solidity ^0.5;

/**
 * @title DOUG - Decentralized Organization Upgrade Guy
 * @dev DOUG is the main Singleton contract to support the lifecycle of solutions and products.
 * It serves as the single point of entry to all administrative functions.
 * Doug is a marmot that lives in Connecticut. We have named our smart contract kernel after this marmot.
 */
contract DOUG {
    
    /**
     * @dev Registers the contract with the given address under the specified ID and performs a deployment
     * procedure which involves dependency injection and upgrades from previously deployed contracts with
     * the same ID.
     * @param _id the ID under which to register the contract
     * @param _address the address of the contract
     * @return true if successful, false otherwise
     */
    function deploy(string calldata _id, address _address) external returns (bool success);

	/**
     * @dev Attempts to register the contract with the given address under the specified ID and version
     * and performs a deployment procedure which involves dependency injection and upgrades from previously
     * deployed contracts with the same ID.
     * @param _id the ID under which to register the contract
     * @param _address the address of the contract
     * @return true if successful, false otherwise
	 */
    function deployVersion(string memory _id, address _address, uint8[3] memory _version) public returns (bool success);

    /**
     * @dev Registers the contract with the given address under the specified ID.
     * @param _id the ID under which to register the contract
     * @param _address the address of the contract
     * @return true if successful, false otherwise
     */
    function register(string calldata _id, address _address) external returns (uint8[3] memory version);

    /**
     * @dev Registers the contract with the given address under the specified ID and version.
     * @param _id the ID under which to register the contract
     * @param _address the address of the contract
	 * @return version - the version under which the contract was registered.
     */
    function registerVersion(string memory _id, address _address, uint8[3] memory _version) public returns (uint8[3] memory version);

    /**
     * @dev Returns the address of a contract registered under the given ID.
     * @param _id the ID under which the contract is registered
     * @return the contract's address
     */
    function lookup(string calldata _id) external view returns (address contractAddress);

    /**
     * @dev Returns the address of the specified version of a contract registered under the given ID.
     * @param _id the ID under which the contract is registered
     * @return the contract's address of 0x0 if the given ID and version cannot be found.
     */
    function lookupVersion(string calldata _id, uint8[3] calldata _version) external view returns (address contractAddress);

}