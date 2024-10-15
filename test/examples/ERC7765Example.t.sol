// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

import "forge-std/Test.sol";
import "../../src/references/MultiplePrivilegeManagement.sol";

contract ERC7765ExampleTest is Test {

    MultiplePrivilegeManagement private example;
    address private owner;
    address private user1;
    uint256 private constant TOKEN_ID = 1;
    uint256 private constant PRIVILEGE_ID = 1;
    uint256 private constant UNKNOWN_PRIVILEGE_ID = 2;

    function setUp() public {
        owner = address(this);
        user1 = address(0xd0C05c200f933987376779184bD5B41DFaAc2D67);
        example = new MultiplePrivilegeManagement("Test Token", "TST", owner);
    }

    function testReleasePrivilege() public {
        example.releasePrivilege(
            "Test Privilege",
            "Privilege for testing",
            block.timestamp + 1000,
            1,
            100
        );

        (
            uint256 id, 
            string memory name,,
            uint256 expiration,,,
        ) = example.privileges(PRIVILEGE_ID);
        
        assertEq(id, PRIVILEGE_ID);
        assertEq(name, "Test Privilege");
        assertTrue(expiration > block.timestamp);
    }

    function testExercisePrivilegeInvalidId() public {
        example.safeMint(user1, TOKEN_ID);

        example.releasePrivilege(
            "Test Privilege",
            "Privilege for testing",
            block.timestamp + 1000,
            1,
            100
        );

        vm.expectRevert("The privilege does not exist");

        vm.prank(user1);
        example.exercisePrivilege(user1, TOKEN_ID, UNKNOWN_PRIVILEGE_ID, "");
    }

    function testExercisePrivilegeInvalidTo() public {
        example.safeMint(user1, TOKEN_ID);

        example.releasePrivilege(
            "Test Privilege",
            "Privilege for testing",
            block.timestamp + 1000,
            1,
            100
        );

        vm.expectRevert("The privilege does not exist");

        vm.prank(owner);
        example.exercisePrivilege(owner, TOKEN_ID, UNKNOWN_PRIVILEGE_ID, "");
    }

    function testExercisePrivilegeInvalidTokenId() public {
        example.safeMint(user1, TOKEN_ID);

        example.releasePrivilege(
            "Test Privilege",
            "Privilege for testing",
            block.timestamp + 1000,
            10,
            100
        );

        vm.expectRevert("The _tokenId is out of range");

        vm.prank(user1);
        example.exercisePrivilege(user1, TOKEN_ID, PRIVILEGE_ID, "");
    }

    function testExercisePrivilegeInvalidExpiration() public {
        example.safeMint(user1, TOKEN_ID);

        example.releasePrivilege(
            "Test Privilege",
            "Privilege for testing",
            block.timestamp - 1000,
            1,
            100
        );

        vm.expectRevert("The privilege has expired");

        vm.prank(user1);
        example.exercisePrivilege(user1, TOKEN_ID, PRIVILEGE_ID, "");
    }

    function testExercisePrivilegeDuplicate() public {
        example.safeMint(user1, TOKEN_ID);

        example.releasePrivilege(
            "Test Privilege",
            "Privilege for testing",
            block.timestamp + 1000,
            1,
            100
        );

        vm.prank(user1);
        example.exercisePrivilege(user1, TOKEN_ID, PRIVILEGE_ID, "");

        vm.expectRevert("You had exercised this privilege");

        vm.prank(user1);
        example.exercisePrivilege(user1, TOKEN_ID, PRIVILEGE_ID, "");
    }

    function testExercisePrivilege() public {
        example.safeMint(user1, TOKEN_ID);

        example.releasePrivilege(
            "Test Privilege",
            "Privilege for testing",
            block.timestamp + 1000,
            1,
            100
        );

        vm.prank(user1);
        example.exercisePrivilege(user1, TOKEN_ID, PRIVILEGE_ID, "");

        address exercisedBy = example.privilegeExercisedInfo(TOKEN_ID, PRIVILEGE_ID);
        assertEq(exercisedBy, user1);

        bool exercisable = example.isExercisable(user1, TOKEN_ID, PRIVILEGE_ID);
        assertFalse(exercisable);
    }

    function testIsExercised() public {
        example.safeMint(user1, TOKEN_ID);
        example.releasePrivilege(
            "Test Privilege",
            "Privilege for testing",
            block.timestamp + 1000,
            1,
            100
        );

        vm.prank(user1);
        example.exercisePrivilege(user1, TOKEN_ID, PRIVILEGE_ID, "");

        bool exercised = example.isExercised(user1, TOKEN_ID, PRIVILEGE_ID);
        assertTrue(exercised);
    }

    function testGetPrivilegeIds() public {
        example.safeMint(user1, TOKEN_ID);
        example.releasePrivilege(
            "Test Privilege",
            "Privilege for testing",
            block.timestamp + 1000,
            1,
            100
        );

        vm.prank(user1);
        example.exercisePrivilege(user1, TOKEN_ID, PRIVILEGE_ID, "");

        uint256[] memory privileges = example.getPrivilegeIds(TOKEN_ID);
        assertEq(privileges.length, 1);
        assertEq(privileges[0], PRIVILEGE_ID);
    }

    function testPrivilegeURI() public {
        example.releasePrivilege(
            "Test Privilege",
            "Privilege for testing",
            block.timestamp + 1000,
            1,
            100
        );

        string memory uri = example.privilegeURI(PRIVILEGE_ID);
        assertTrue(bytes(uri).length > 0);
    }
}
