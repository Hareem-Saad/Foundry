// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./Imports.sol";

contract tokenQTKN is ERC20, Ownable{
    //price
    uint256 public price = 0.01 ether;

    //creation of token
    constructor() ERC20("QTKN", "QTKN") {}

    //mint function
    //anyone can mint
    //has to pay price corresponding to the amount they are buying
    function mint(address _to, uint256 _amount) public onlyOwner() {
        _approve(_to, owner(), _amount*10**18);
        _mint(_to, _amount*10**18);
    }

    //add approve function in which the user approves the school contract
    function updatePriceInWei(uint _price) public onlyOwner {
        price = _price;
    }
}

contract proxyTKN is ERC20, Ownable{

    //mapping(tokenid => (courseid => address))
    mapping(uint => mapping(uint => address)) public isEnrolled;
    mapping(uint => address) public tokenOf;


    //creation of token
    constructor() ERC20("proxyTKN", "PTKN") {}

    //mint function
    //anyone can mint
    //has to pay price corresponding to the amount they are buying
    function mint(address _to, uint courseId) public onlyOwner() {
        _mint(_to, 1);
        isEnrolled[totalSupply()][courseId] = _to;
        tokenOf[totalSupply()] = _to;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        revert();
        return true;
    }

    function ifEnrolled(uint tokenid, uint _courseIndex) public view returns (address) {
        return isEnrolled[tokenid][_courseIndex];
    }

    function _transferEnrollment(address to, uint courseId, uint256 amount, uint tokenId) public {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        isEnrolled[tokenId][courseId] = to;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        revert();
        return true;
    }

    function transferFrom(address from, address to, uint256 amount, uint courseId, uint tokenId) public {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        isEnrolled[tokenId][courseId] = to;
    }
    
}