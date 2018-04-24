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

        uint user0PostBetBalance = address(user0).balance;
        uint user1PostBetBalance = address(user1).balance;

        assertTrue(address(twoUp).balance == twoUp.AVG_PRICE() * 2);

        boxer.pickSpinner(gId);

        TwoUp.Game memory g;
        (g.hashedSeed, g.blockNumberToUse, g.spinner, g.state) = twoUp.games(gId);
        assertTrue(g.spinner == address(user0));

        bytes32 seed = "blah";
        bytes32 hashedSeed = keccak256(seed);
        user0.flipKip(gId, hashedSeed);
        (g.hashedSeed, g.blockNumberToUse, g.spinner, g.state) = twoUp.games(gId);
        assertTrue(g.state == TwoUp.GameState.SPINNING);

        user0.reviewResults(gId, seed);
        (g.hashedSeed, g.blockNumberToUse, g.spinner, g.state) = twoUp.games(gId);
        if (g.state == TwoUp.GameState.OPEN) { //one winner paid out, one loser unchanged
            bool user0win = ((user1PostBetBalance == address(user1).balance)
            && (user0PostBetBalance + twoUp.AVG_PRICE() * 2 == address(user0).balance));
            bool user1win = ((user0PostBetBalance == address(user0).balance)
            && (user1PostBetBalance + twoUp.AVG_PRICE() * 2 == address(user1).balance));
            assertTrue(user0win || user1win);
        } else { // needs reflip
            assertTrue(g.state == TwoUp.GameState.CLOSED);
        }
    }

}
