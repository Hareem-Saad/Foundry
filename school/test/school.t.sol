// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/School.sol";

// error shareTermTooLow();

contract SchoolTest is Test {
    School public school;
    address teacher = address(1);

    function setUp() public {
        school = new School();
    }

    function testCreateCourse() public {
        school.createCourse("ICS", teacher, 50, 10, "pop");
        assertEq(school.cnft().viewCourseTeacherById(1), teacher);
    }

    function testFailCreateCoursePrice() public {
        vm.expectRevert(bytes("price is lower than the minimum course price"));
        school.createCourse("ICS", teacher, 50, 0, "pop");
    }
    
    function testFailCreateCourseShareTerm() public {
        vm.expectRevert(bytes("share term is lower than the base term"));
        school.createCourse("ICS", teacher, 0, 10, "pop");
    }
}
