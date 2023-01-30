// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
// import "C:/Users/User/Desktop/_Foundry/school/src/School.sol";

import "../src/School.sol";

// error shareTermTooLow();

contract SchoolTest is Test {


    School public school;
    address teacher = address(1);
    address student = address(2);
    address zero = address(0x0);

    function setUp() public {
        school = new School();
    }

    function testCreateCourse() public {
        school.createCourse("ICS", teacher, 50, 10, "pop");
        vm.prank(teacher);
        school.activateCourse(1);
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
    
    function testCreateCourseZeroAddress() public {
        vm.expectRevert(bytes("user not viable"));
        school.createCourse("ICS", zero, 50, 10, "pop");
    }

    event newCourse (
        uint256 indexed courseId,
        string name,
        address caller,
        address indexed assignedTeacher,
        uint256 basePrice, 
        uint256 shareTerm,
        uint256 coursePrice,
        uint256 schoolShareAmount
    );

    function testCreateCourseEvent() public {
        
        vm.expectEmit(true, true, true, true);

        // We emit the event we expect to see.
        emit newCourse(1, "ICS", address(this), teacher, 50000000000000000000, 10, 56500000000000000000, 6500000000000000000);

        // We perform the call.
        school.createCourse("ICS", teacher, 50, 10, "pop");
    }

    function test_createCourse_withFuzzing(uint256 _price, uint8 _shareTerm) public {
       console.log("Should handle fuzzing");
       /// inform the constraints to the fuzzer, so that the tests don't revert on bad inputs.
       vm.assume(_price >= 10 && _price <= 5000);
       vm.assume(_shareTerm >= 10 && _shareTerm <= 100);
       school.createCourse("ICS", teacher, _price, _shareTerm, "pop");
    }

    function testMint() public {
        vm.deal(student, 1.5 ether);
        vm.startPrank(student);
        school.mint{value: 1 ether}(100);
        assertEq(school.qtknContract().balanceOf(student), 100*10**18);
        vm.stopPrank();
    }

    function testEnroll() public {
        testCreateCourse();
        testMint();
        vm.startPrank(student);
        school.enroll(1);
        assertEq(school.qtknContract().balanceOf(student), 43.5*10**18);
        assertEq(school.qtknContract().balanceOf(teacher), 50*10**18);
        assertEq(school.qtknContract().balanceOf(address(this)), 6.5*10**18);
        assertEq(school.ptknContract().balanceOf(student), 1);
        assertEq(school.ptknContract().ifEnrolled(1, 1), student);
        // assertEq(school.viewCourseStudentStatusById(1, student), 1);

        vm.stopPrank();
    }

    function testGraduate() public {
        //create course
        school.createCourse("ICS", teacher, 50, 10, "pop");
        vm.prank(teacher);
        school.activateCourse(1);

        //student mint tokens
        vm.deal(student, 1 ether);
        vm.prank(student);
        school.mint{value: 1 ether}(100);

        //student enrolls
        vm.prank(student);
        school.enroll(1);

        //graduation
        vm.startPrank(teacher);
        school.graduate(1, 1, student);
        assertEq(school.certificateContract().ownerOf(1), student);
        // assertEq(school.viewCourseStudentStatusById(1, student), 2);

        vm.stopPrank();
    }
}
