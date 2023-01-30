// SPDX-License-Identifier: GPL-3.0

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity >=0.7.0 <0.9.0;

// import "C:/Users/User/Desktop/_Foundry/school/src/Imports.sol";
import "./Imports.sol";

contract Certificate is EERC721, Ownable {
    uint256 public id = 0;

    constructor() EERC721 ("QTKN", "QTKN") {}

    function mint (address _to) public onlyOwner {
        id += 1;
        _safeMint(_to, id);
    }
}

// contract CourseNFT is Ownable, ERC721URIStorage{
//     uint256 public tokenCounter = 0;
//     string private uri = 'https://gateway.pinata.cloud/ipfs/QmUwGLS68RfgDLxdVGKUyFs3ypX88jkxSJaX2U2TXPa2BD/1.json';
//     constructor() ERC721("Q-Course", "QCRS") {

//     }

//     function mint(address _to) public onlyOwner {
//         tokenCounter += 1;
//         _mint(_to, tokenCounter);
//         _setTokenURI(tokenCounter, uri);
//     }
// }

contract CourseNFT is ERC1155, Ownable {

    enum studentStatus {NOT_ENROLLED, ENROLLED, COMPLETED}
    // enum courseStatus {NOT_ACTIVE, ACTIVE}

    studentStatus public studentDefault = studentStatus.NOT_ENROLLED; //default student status

    struct Course {
        uint256 courseId; //also nft id
        string name;
        address assignedTeacher;
        uint256 basePrice; //teacher's price
        uint256 shareTerm; //percentage of school's share 
        uint256 coursePrice; //course price after adding school's share and tax
        bool isActive;
        mapping (address => studentStatus) students;
    }

    mapping (address => uint256[]) private teacherCourses;

    mapping (uint256 => Course) private courses;

    uint256 public tokenCounter = 0;
    
    
    constructor() ERC1155("https://gateway.pinata.cloud/ipfs/QmUwGLS68RfgDLxdVGKUyFs3ypX88jkxSJaX2U2TXPa2BD/1.json") {

    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(
        bytes memory data, 
        string memory _courseName, 
        address _teacher, 
        uint256 _price, 
        uint8 _shareTerm, 
        uint256 coursePrice
    ) public onlyOwner returns(uint256 courseId) {
        tokenCounter += 1;
        //create course instance
        Course storage c = courses[tokenCounter];
        c.courseId = tokenCounter;
        c.name = _courseName;
        c.assignedTeacher = _teacher;
        c.basePrice = _price;
        c.shareTerm = _shareTerm;
        c.coursePrice = coursePrice;
        //add to teachers mapping
        teacherCourses[_teacher].push(tokenCounter);
        //mint
        _mint(_teacher, tokenCounter, 1, data);
        return(tokenCounter);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }

    function viewCoursesById(address addr) public view returns (uint256[] memory) {
        return teacherCourses[addr];
    }

    function viewCourseNameById(uint256 id) public view returns (string memory) {
        return courses[id].name;
    }

    function viewCourseTeacherById(uint256 id) public view returns (address) {
        return courses[id].assignedTeacher;
    }

    function viewShareTermsById(uint256 id) public view returns (uint256) {
        return courses[id].shareTerm;
    }

    function viewBasePriceById(uint256 id) public view returns (uint256) {
        return courses[id].basePrice;
    }

    function viewCoursePriceById(uint256 id) public view returns (uint256) {
        return courses[id].coursePrice;
    }

    function viewCourseStatusById(uint256 id) public view returns (bool) {
        return courses[id].isActive;
    }

    function viewCourseStudentStatusById(uint256 id, address student) public view returns (studentStatus) {
        return courses[id].students[student];
    }

    function graduateStudent(uint256 id, address student) public onlyOwner {
        courses[id].students[student] = studentStatus.COMPLETED;
    }

    function EnrollStudent(uint256 id, address student) public onlyOwner {
        courses[id].students[student] = studentStatus.ENROLLED;
    }

    function activateCourse(uint256 id) public onlyOwner {
        courses[id].isActive = true;
    }

    function deactivateCourse(uint256 id) public onlyOwner {
        courses[id].isActive = false;
    }

    // function calculatePrice(uint256 basePrice, uint256 shareTerm, uint16 tax) internal pure returns (uint) {
    //     return (basePrice + calculateSharePrice(basePrice, shareTerm) + calculateTaxPrice(basePrice, tax));
    // }

    // //calculate share price
    // function calculateSharePrice(uint256 basePrice, uint256 shareTerm) internal pure returns (uint) {
    //     return (basePrice * shareTerm / 100);
    // }

    // //calculate tax price
    // function calculateTaxPrice(uint256 basePrice, uint16 tax) internal pure returns (uint) {
    //     return basePrice * tax / 100;
    // }

    
}