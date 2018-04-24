pragma solidity ^0.4.22;

import "ds-test/test.sol";

import "./twoUp.sol";


contract User {

    TwoUp public twoUp;

    constructor(TwoUp _twoUp) public {
        twoUp = _twoUp;
    }


    function () public payable {}

}

contract TwoUpTest is DSTest {
    TwoUp internal twoUp;

    User internal boxer;

    User internal user0;
    User internal user1;


    function setUp() public {
        twoUp = new TwoUp();
        boxer = new User(twoUp);
        twoUp.setBoxer(boxer);

        user0 = new User(twoUp);
        address(user0).transfer(1 ether);
        user1 = new User(twoUp);
        address(user1).transfer(1 ether);

    }

    function test_01_simple() public {
        assertTrue(true);
    }

}
