pragma solidity ^0.4.23;

import "ds-test/test.sol";

import "./twoUp.sol";


contract User {

    TwoUp public twoUp;

    constructor(TwoUp _twoUp) public {
        twoUp = _twoUp;
    }

    function () public payable {}

    function createGame() public returns (uint) {
        return twoUp.createGame();
    }

    function guessHeads(uint _gameId) public {
        twoUp.guessHeads.value(twoUp.AVG_PRICE())(_gameId);
    }

    function guessTails(uint _gameId) public {
        twoUp.guessTails.value(twoUp.AVG_PRICE())(_gameId);
    }

    function pickSpinner(uint _gameId) public {
        twoUp.pickSpinner(_gameId);
    }

    function newSpinner(uint _gameId) public {
        twoUp.newSpinner(_gameId);
    }

    function flipKip(uint _gameId, bytes32 _hashedSeed) public {
        twoUp.flipKip(_gameId, _hashedSeed);
    }

    function reviewResults(uint _gameId, bytes32 _seed) public {
        twoUp.reviewResults(_gameId, _seed);
    }
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
        uint gId = user0.createGame();
        user0.guessHeads(gId);
        // share game id with other user
        user1.guessTails(gId);

        assertTrue(address(twoUp).balance == twoUp.AVG_PRICE() * 2);

    }

}
