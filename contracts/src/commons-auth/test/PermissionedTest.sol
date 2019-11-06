pragma solidity ^0.5;

import "commons-collections/AbstractDataStorage.sol";
import "commons-collections/AbstractAddressScopes.sol";
import "commons-auth/AbstractPermissioned.sol";
import "commons-auth/DefaultOrganization.sol";
import "commons-standards/AbstractERC165.sol";

contract PermissionedTest {
	
	string constant SUCCESS = "success";

	bytes32 constant permission1 = "test.permission1";
	bytes32 constant permission2 = "test.permission2";
	bytes32 constant permission3 = "test.permission3";
	bytes32 constant permission4 = "test.permission4";

	string constant functionSigCreatePermission = "createPermission(bytes32,bool,bool,bool)";
	string constant functionSigGrantPermission = "grantPermission(bytes32,address)";
	string constant functionSigRevokePermission = "revokePermission(bytes32,address)";
	string constant functionSigTransferPermission = "transferPermission(bytes32,address)";
	string constant functionSigPermissionedFunction = "permissionedFunction()";

	/**
	 * @dev Tests the functions of a Permissioned contract
	 */
	function testPermissions() external returns (string memory) {

		bool success;

		// Make a permissioned object with no pre-determined admin
		PermissionedObject object1 = new PermissionedObject(address(0));
		if (!object1.hasPermission(object1.ROLE_ID_OBJECT_ADMIN(), address(this))) return "The test contract should be the admin for object1";

		// Make a permissioned object with pre-determined admin
		PermissionedObject object2 = new PermissionedObject(msg.sender);
		if (!object2.hasPermission(object2.ROLE_ID_OBJECT_ADMIN(), msg.sender)) return "The test msg.sender should be the admin for object2";

		// verify function signatures are all working before testing revert scenarios!
		(success, ) = address(object1).call(abi.encodeWithSignature(functionSigCreatePermission, permission1, true, true, true));
		if (!success) return "functionSigCreatePermission should work in call()";
		(success, ) = address(object1).call(abi.encodeWithSignature(functionSigGrantPermission, permission1, address(this)));
		if (!success) return "functionSigGrantPermission should work in call()";
		(success, ) = address(object1).call(abi.encodeWithSignature(functionSigTransferPermission, permission1, msg.sender));
		if (!success) return "functionSigTransferPermission should work in call()";
		(success, ) = address(object1).call(abi.encodeWithSignature(functionSigRevokePermission, permission1, msg.sender));
		if (!success) return "functionSigRevokePermission should work in call()";

    	// Create and set up more permissions with different attributes
		object1.createPermission(permission2, true, false, false);
		object1.grantPermission(permission2, address(this));
		object1.createPermission(permission3, false, false, false);
		object1.grantPermission(permission3, address(this));

    	// Make another permissioned object and permissions for testing pre_requiresPermission
		PermissionedObject object3 = new PermissionedObject(address(this));
		object3.createPermission(permission1, true, true, true);
		object3.createPermission(permission2, true, true, true);
		object3.grantPermission(permission2, msg.sender);
		object3.grantPermission(permission2, address(this));
		object3.transferPermission(object3.ROLE_ID_OBJECT_ADMIN(), msg.sender);

		// test view functions
		(bool exists, bool multiHolder, bool revocable, bool transferable, uint holderSize) = object3.getPermissionDetails(permission2);
		if (!exists) return "Details for permission2 should show exists==true";
		if (!multiHolder) return "Details for permission2 should show multiHolder==true";
		if (!revocable) return "Details for permission2 should show revocable==true";
		if (!transferable) return "Details for permission2 should show transferable==true";
		if (holderSize != 2) return "Details for permission2 should show holderSize==2";
		if (object3.getHolder(permission2, 0) != msg.sender) return "Holder at idx 0 for permission2 should be msg.sender";
		if (object3.getHolder(permission2, 1) != address(this)) return "Holder at idx 1 for permission2 should be test contract";
		if (object3.getHolder(permission2, 3) != address(0)) return "Holder at idx 2 for permission2 with non-existent index should return 0x0";

		// Revert Scenarios:

		/* createPermission
			1. Fails pre_requiresPermission(ROLE_ID_OBJECT_ADMIN)
			2. Permission already exists
		*/
		(success, ) = address(object3).call(abi.encodeWithSignature(functionSigCreatePermission, permission1, true, true, true));
		if (success) return "Creating a permission without the admin role should revert";
		(success, ) = address(object1).call(abi.encodeWithSignature(functionSigCreatePermission, permission1, true, false, false));
		if (success) return "Creating a permission that already exists should revert";

		/* grantPermission
			1. Fails pre_requiresPermission(ROLE_ID_OBJECT_ADMIN)
			2. Permission does not exist
			3. Overwritting an already-granted single-holder permission
		*/
		(success, ) = address(object3).call(abi.encodeWithSignature(functionSigGrantPermission, permission1, msg.sender));
		if (success) return "Granting a permission without the admin role should revert";
		(success, ) = address(object1).call(abi.encodeWithSignature(functionSigGrantPermission, "fakePermission", msg.sender));
		if (success) return "Granting a non-existent permission should revert";
		(success, ) = address(object1).call(abi.encodeWithSignature(functionSigGrantPermission, permission3, msg.sender));
		if (success) return "Re-granting a single-holder permission should revert";

		/* transferPermission
			1. Permission does not exist
			2. Permission is not transferable
			3. msg.sender does not hold the specified permission
			4. Permission is already held by specified account
		*/
		(success, ) = address(object1).call(abi.encodeWithSignature(functionSigTransferPermission, "fakePermission", msg.sender));
		if (success) return "Transfering a non-existant permission should revert";
		(success, ) = address(object1).call(abi.encodeWithSignature(functionSigTransferPermission, permission2, msg.sender));
		if (success) return "Transfering a non-transferable permission should revert";
    	object1.grantPermission(permission1, msg.sender);
		(success, ) = address(object1).call(abi.encodeWithSignature(functionSigTransferPermission, permission1, address(this)));
		if (success) return "Transfering a permission from an account that does not hold the permission should revert";
    	object1.revokePermission(permission1, msg.sender);
    	object1.grantPermission(permission1, address(this));
		(success, ) = address(object1).call(abi.encodeWithSignature(functionSigTransferPermission, permission1, address(this)));
		if (success) return "Transfering a permission to an account already holding the permission should revert";

		/* revokePermission
			1. Fails pre_requiresPermission(ROLE_ID_OBJECT_ADMIN)
			2. Permission does not exist
			3. Permission is not revocable
			4. Permission is not held by specified account
		*/
		(success, ) = address(object3).call(abi.encodeWithSignature(functionSigRevokePermission, permission2, msg.sender));
    	if (success) return "Revoking another account's permission without the admin role should revert";
		(success, ) = address(object1).call(abi.encodeWithSignature(functionSigRevokePermission, "fakePermission", msg.sender));
  		if (success) return "Revoking a non-existent permission should revert";
		(success, ) = address(object1).call(abi.encodeWithSignature(functionSigRevokePermission, permission2, address(this)));
		if (success) return "Revoking a non-revocable permission should revert";
		(success, ) = address(object1).call(abi.encodeWithSignature(functionSigRevokePermission, object1.ROLE_ID_OBJECT_ADMIN(), address(this)));
		if (success) return "Revoking the admin permission from the only holder should revert";
		(success, ) = address(object1).call(abi.encodeWithSignature(functionSigRevokePermission, permission1, msg.sender));
		if (success) return "Revoking a permission from an account that doesn't hold the permission should revert";

		// Test various multi-holder permissions
		if (!object1.hasPermission(permission1, address(this))) return "Test contract should have permission1 on object1";
		if (object1.hasPermission(permission1, msg.sender)) return "msg.sender should not have permission1 on object1";
		object1.grantPermission(permission1, msg.sender);
		if (!object1.hasPermission(permission1, msg.sender)) return "msg.sender should have permission1 on object1";
		object1.revokePermission(permission1, msg.sender);
		if (object1.hasPermission(permission1, msg.sender)) return "msg.sender should have had permission1 on object1 revoked from them";
		object1.transferPermission(permission1, msg.sender);
		if (!object1.hasPermission(permission1, msg.sender)) return "msg.sender should have had permission1 on object1 transfered to them";
		if (object1.hasPermission(permission1, address(this))) return "Test contract should have had permission1 on object1 transfered from them";

		// Test transfer of object admin role
		object1.transferPermission(object1.ROLE_ID_OBJECT_ADMIN(), msg.sender);
		if (!object1.hasPermission(object1.ROLE_ID_OBJECT_ADMIN(), msg.sender)) return "The msg.sender should be the admin after transfer from test contract";

		// Test pre_requiresPermissionWithContext

		// Should allow MSG.SENDER with the SINGLE-holder permission to call guarded function
		ScopedPermissionedObject object4 = new ScopedPermissionedObject(address(0));
		object4.createPermission(permission1, false, true, false);
		object4.grantPermission(permission1, address(this));
		(success, ) = address(object4).call(abi.encodeWithSignature(functionSigPermissionedFunction));
		if (!success) return "permissionedFunction with single-holder permission should work in call() by msg.sender";
		object4.revokePermission(permission1, address(this));
		// Should NOT allow MSG.SENDER without the SINGLE-holder permission to call guarded function
		(success, ) = address(object4).call(abi.encodeWithSignature(functionSigPermissionedFunction));
		if (success) return "Calling guarded permissionedFunction should revert if msg.sender does not hold the single-holder permission";

		// Should allow MSG.SENDER with the MULTI-holder permission to call guarded function
		object4 = new ScopedPermissionedObject(address(0));
		object4.createPermission(permission1, true, true, false);
		object4.grantPermission(permission1, address(object4));
		object4.grantPermission(permission1, address(this));

		(success, ) = address(object4).call(abi.encodeWithSignature(functionSigPermissionedFunction));
		if (!success) return "permissionedFunction with multi-holder permission should work in call() by msg.sender";
		object4.revokePermission(permission1, address(this));
		// Should NOT allow MSG.SENDER without the MULTI-holder permission to call guarded function
		(success, ) = address(object4).call(abi.encodeWithSignature(functionSigPermissionedFunction));
		if (success) return "Calling guarded permissionedFunction should revert if msg.sender does not hold the multi-holder permission";

		// Test organization, and scopes setup
		bytes32 empty = "";
		bytes32 context = "context";
		address[] memory emptyAddressArray;
		Organization org1 = new DefaultOrganization();
		org1.initialize(emptyAddressArray, empty);
		org1.addUser(address(this));

		// Should allow ORGANIZATION MEMBER with the SINGLE-holder permission to call guarded function of a NON-SCOPED object
		PermissionedObject object5 = new PermissionedObject(address(0));
		object5.createPermission(permission1, false, true, false);
		object5.grantPermission(permission1, address(org1));
		(success, ) = address(object5).call(abi.encodeWithSignature(functionSigPermissionedFunction));
		if (!success) return "permissionedFunction should work in call() by member of the permission-holder organization";
		// Remove user from organization to cause revert
		org1.removeUser(address(this));
		(success, ) = address(object5).call(abi.encodeWithSignature(functionSigPermissionedFunction));
		if (success) return "Calling guarded permissionedFunction should revert if msg.sender is not in the permission-holder organization";

		// Should allow ORGANIZATION MEMBER with the MULTI-holder permission to call guarded function of a NON-SCOPED object
		org1.addUser(address(this));
		object5 = new PermissionedObject(address(0));
		object5.createPermission(permission1, true, true, false);
		object5.grantPermission(permission1, address(object4));
		object5.grantPermission(permission1, address(org1));
		(success, ) = address(object5).call(abi.encodeWithSignature(functionSigPermissionedFunction));
		if (!success) return "permissionedFunction should work in call() by member of a permission-holder organization";
		// Remove user from organization to cause revert
		org1.removeUser(address(this));
		(success, ) = address(object5).call(abi.encodeWithSignature(functionSigPermissionedFunction));
		if (success) return "Calling guarded permissionedFunction should revert if msg.sender is not in a permission-holder organization";


		// Should allow ORGANIZATION MEMBER with the SINGLE-holder permission to call guarded function of a SCOPED object
		org1.addUser(address(this));
		object4 = new ScopedPermissionedObject(address(0));
		object4.createPermission(permission1, false, true, false);
		object4.grantPermission(permission1, address(org1));
		object4.setAddressScope(address(org1), context, org1.getOrganizationKey(), empty, empty, address(0));
		(success, ) = address(object4).call(abi.encodeWithSignature(functionSigPermissionedFunction));
		if (!success) return "permissionedFunction should work in call() by member of the permission-holder organization and department defined by scope";
		org1.addDepartment(context);
		object4.setAddressScope(address(org1), context, context, empty, empty, address(0));
		(success, ) = address(object4).call(abi.encodeWithSignature(functionSigPermissionedFunction));
		if (success) return "Calling guarded permissionedFunction should revert if msg.sender is not in the permission-holder organization and department defined by scope";

		// Should allow ORGANIZATION MEMBER with the MULTI-holder permission to call guarded function of a SCOPED object
		object4 = new ScopedPermissionedObject(address(0));
		object4.createPermission(permission1, true, true, false);
		object4.grantPermission(permission1, address(object5));
		object4.grantPermission(permission1, address(org1));
		object4.setAddressScope(address(org1), context, org1.getOrganizationKey(), empty, empty, address(0));
		(success, ) = address(object4).call(abi.encodeWithSignature(functionSigPermissionedFunction));
		if (!success) return "permissionedFunction should work in call() by member of a permission-holder organization and department defined by scope";
		// Change department defined in scope to cause revert
		object4.setAddressScope(address(org1), context, context, empty, empty, address(0));
		(success, ) = address(object4).call(abi.encodeWithSignature(functionSigPermissionedFunction));
		if (success) return "Calling guarded permissionedFunction should revert if msg.sender is not in a permission-holder organization and department defined by scope";

		return SUCCESS;
	}
}

contract PermissionedObject is AbstractPermissioned {

	address creator;
	bytes32 permission1 = "test.permission1";
  bytes32 context = "context";

	constructor(address _creator) AbstractPermissioned() public {
		initializeObjectAdministrator(_creator);
		creator = _creator;
	}

  function permissionedFunction() public pre_requiresPermissionWithContext(permission1, context) {
    return;
  }

}

contract ScopedPermissionedObject is AbstractERC165, AbstractDataStorage, AbstractAddressScopes, AbstractPermissioned {

	address creator;
	bytes32 permission1 = "test.permission1";
  bytes32 context = "context";

	constructor(address _creator) AbstractPermissioned() public {
		addInterfaceSupport(ERC165_ID_Address_Scopes);
		initializeObjectAdministrator(_creator);
		creator = _creator;
	}

  function permissionedFunction() public pre_requiresPermissionWithContext(permission1, context) {
    return;
  }

}
