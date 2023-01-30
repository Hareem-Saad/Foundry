// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./Certificate.sol";
import "./Token.sol";
import "./Imports.sol";

// import "C:/Users/User/Desktop/_Foundry/school/src/Imports.sol";
// import "C:/Users/User/Desktop/_Foundry/school/src/Certificate.sol";
// import "C:/Users/User/Desktop/_Foundry/school/src/Token.sol";

// import "hardhat/console.sol";

//here token contract is diff
contract School is Ownable{ 

    //important
    //owner of all contract should be same otherwise certifications wont work
    uint16 public tax = 3; //default tax
    uint256 minimumCoursePrice = 10; //minimum course fee
    uint256 baseTerm = 10; //schools share
    Certificate public certificateContract; //pointer to nft contract
    tokenQTKN public qtknContract; //pointer to nft contract
    proxyTKN public ptknContract; //pointer to nft contract
    CourseNFT public cnft; //course nft


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

    event newStudentAdded (
        uint256 indexed courseId,
        uint256 tokenId,
        string name,
        address indexed assignedTeacher,
        uint256 coursePrice,
        address indexed student
    );

    event studentGraduated (
        uint256 indexed courseId,
        address indexed assignedTeacher,
        address indexed student
    );

    constructor() {
        certificateContract = new Certificate();
        qtknContract = new tokenQTKN();
        cnft = new CourseNFT();
        ptknContract = new proxyTKN();
    }

    modifier onlyTeacher(uint courseId) {
        require(cnft.viewCourseTeacherById(courseId) == msg.sender, "not the assigned teacher");
        _;
    }

    //functions for owner

    function setTax(uint16 _tax) public onlyOwner {
        tax = _tax;
    }

    function setBaseTerm(uint256 _baseTerm) public onlyOwner {
        baseTerm = _baseTerm;
    }

    function setMinimumCoursePrice(uint256 _minimumCoursePrice) public onlyOwner {
        minimumCoursePrice = _minimumCoursePrice;
    }

    //functions for teacher

    /**
     * Create Course
     * @param _price = teacher's price || must be > minimum price
     * @param _shareTerm = teacher's share term || must be > minimum term
     * @param data = concatenated string with information such as 
     *      course id = from cnft tokencounter + 1
     *      course name = from input (front-end)
     *      course teacher = from input (front-end)
     *      teacher's price = from input (front-end multipled by 10**18)
     *      teacher's share term = from input (front-end multipled NOT by 10**18)
     *      course price = from front-end calculated by calculatePrice from contract
     *      school fee = from front-end calculated by course price - teacher's share term
     */
    function createCourse(string memory _courseName, address _teacher, uint256 _price, uint8 _shareTerm, string memory data) public {
        require(_price >= minimumCoursePrice && _price <= 5000, "price is lower than the minimum course price");
        require(_shareTerm >= baseTerm, "share term is lower than the base term");
        require(msg.sender != address(0), "user not viable");
        require(_teacher != address(0), "user not viable");
        require(keccak256(abi.encode(_courseName)) != keccak256(abi.encode("")) , "name cannot be null");
        // require(keccak256(abi.encode(data)) == keccak256(abi.encode("")) , "name cannot be null");
        // require(date != "", "data cannot be null");
        uint basePrice = _price*10**18;
        uint price = calculatePrice(basePrice, _shareTerm);
        uint schoolfee = price - basePrice;

        uint id = cnft.mint(bytes(data), _courseName, _teacher, basePrice, _shareTerm, price);
        emit newCourse(id, _courseName, msg.sender, _teacher, basePrice, _shareTerm, price, schoolfee);
    }

    //once a student completes the course the teacher van graduate him
    //once the stutus is complete an nft is transfered to him
    function graduate(uint tokenid, uint _courseIndex, address _student) public onlyTeacher(_courseIndex) {
        // require(cnft.viewCourseTeacherById(_courseIndex) == msg.sender, "not the assigned teacher");
        require(ptknContract.ifEnrolled(tokenid, _courseIndex) == _student, "student not enrolled");
        require(cnft.viewCourseTeacherById(_courseIndex) != address(0), "course doesn't exist");
        cnft.graduateStudent(_courseIndex, _student);
        certificateContract.mint(_student);
        emit studentGraduated(_courseIndex, msg.sender, _student);
    }

    //private functions

    function calculatePrice(uint256 basePrice, uint256 shareTerm) public view returns (uint) {
        return (basePrice + calculateSharePrice(basePrice, shareTerm) + calculateTaxPrice(basePrice));
    }

    //calculate share price
    function calculateSharePrice(uint256 basePrice, uint256 shareTerm) public pure returns (uint) {
        return (basePrice * shareTerm / 100);
    }

    //calculate tax price
    function calculateTaxPrice(uint256 basePrice) public view returns (uint) {
        return basePrice * tax / 100;
    }

    //when a student pays fee this function divides the fee between entities
    function divideFee(address assignedTeacher, uint256 basePrice, uint256 coursePrice) private {
        uint256 schoolfee = coursePrice - basePrice;
        qtknContract.transfer(owner(), schoolfee);
        qtknContract.transfer(assignedTeacher, basePrice);
    }

    //functions for students

    function enroll(uint _courseId) public {
        uint256 coursePrice = cnft.viewCoursePriceById(_courseId);
        uint256 basePrice = cnft.viewBasePriceById(_courseId);
        
        require(msg.sender != address(0), "user not viable");
        require(qtknContract.allowance(msg.sender, address(this)) >= coursePrice , "Check the token allowance");
        require(qtknContract.balanceOf(msg.sender) >= coursePrice);
        require(viewCourseStatusById(_courseId), "course not active");
        
        string memory _name = cnft.viewCourseNameById(_courseId);
        address assignedTeacher = cnft.viewCourseTeacherById(_courseId);
        
        qtknContract.transferFrom(msg.sender, address(this), coursePrice);
        divideFee(assignedTeacher, basePrice, coursePrice);
        cnft.EnrollStudent(_courseId, msg.sender);
        ptknContract.mint(msg.sender, _courseId);
        
        emit newStudentAdded(_courseId, ptknContract.totalSupply(),_name, assignedTeacher, coursePrice, msg.sender);
    }

    function mint(uint256 _amount) public payable {
        require(msg.value == (_amount*qtknContract.price()), "Not enough ethers");
        qtknContract.mint(msg.sender, _amount);
    }

    function updatePriceInWei(uint _price) public onlyOwner {
        qtknContract.updatePriceInWei(_price);
    }

    function viewCoursesById(address addr) public view returns (uint256[] memory) {
        return cnft.viewCoursesById(addr);
    }

    function viewCourseNameById(uint256 id) public view returns (string memory) {
        return cnft.viewCourseNameById(id);
    }

    function viewCourseTeacherById(uint256 id) public view returns (address) {
        return cnft.viewCourseTeacherById(id);
    }

    function viewShareTermsById(uint256 id) public view returns (uint256) {
        return cnft.viewShareTermsById(id);
    }

    function viewBasePriceById(uint256 id) public view returns (uint256) {
        return cnft.viewBasePriceById(id);
    }

    function viewCoursePriceById(uint256 id) public view returns (uint256) {
        return cnft.viewCoursePriceById(id);
    }

    function viewCourseStudentStatusById(uint256 id, address student) public view returns (CourseNFT.studentStatus) {
        return cnft.viewCourseStudentStatusById(id, student);
    }

    function viewCourseStatusById(uint256 id) public view returns (bool) {
        return cnft.viewCourseStatusById(id);
    }

    function activateCourse(uint256 courseId) public onlyTeacher(courseId) {
        require ((courseId != 0) && (courseId <= cnft.tokenCounter()), "course doesnot exist");
        cnft.activateCourse(courseId);
    }

    function deactivateCourse(uint256 courseId) public onlyTeacher(courseId) {
        require ((courseId != 0) && (courseId <= cnft.tokenCounter()), "course doesnot exist");
        cnft.deactivateCourse(courseId);
    }
}