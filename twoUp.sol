pragma solidity ^0.4.23;


contract TwoUp {

    enum CoinResult {HEADSHEADS, HEADSTAIL, TAILHEADS, TAILSTAILS}

    mapping (uint => Game) public games;
    uint constant public AVG_PRICE = 0.01 ether;

    struct Game {
        address[] heads;
        address[] tails;
        bytes32 hashedSeed;
        uint blockNumberToUse;
        address spinner;
        GameState state;
    }

    enum GameState {OPEN, FULL, CLOSED, SPINNING}

    modifier gameOpen(uint _gameId) {
        require(games[_gameId].state == GameState.OPEN, "Game round not open");
        _;
    }

    modifier isSpinner(uint _gameId, address _player) {
        address spinner = games[_gameId].spinner;
        require(spinner != address(0), "Spinner not selected");
        require(spinner == _player, "Player is not the selected spinner");
        _;
    }

    function createGame() public view returns (uint _gameId) {
        return uint(keccak256(msg.sender, blockhash(block.number-1)));
    }

    // require game.state open
    function guessHeads(uint _gameId) public payable gameOpen(_gameId) {
        require(msg.value >= AVG_PRICE);
        games[_gameId].heads.push(msg.sender);
    }

    // require game.state open
    function guessTails(uint _gameId) public payable gameOpen(_gameId) {
        require(msg.value >= AVG_PRICE);
        games[_gameId].tails.push(msg.sender);
    }

    // spinner chosen from heads addresses at random, game.state changes to closed.
    function pickSpinner(uint _gameId) public returns (address) {
        Game storage g = games[_gameId];
        require(g.state == GameState.OPEN || g.state == GameState.FULL,
            "Game not in expected state for this function");
        address[] storage heads = g.heads;
        g.spinner = heads[uint(keccak256(blockhash(block.number-1))) % heads.length];
        //truncate unmached guesses
        if (g.heads.length > g.tails.length) {
            g.heads.length = g.tails.length;
        } else {
            g.tails.length = g.heads.length;
        }
        g.state = GameState.CLOSED;
        return g.spinner;
    }

    // spinner only, closes game
    function flipKip(uint _gameId, bytes32 _hashedSeed) public isSpinner(_gameId, msg.sender) {
        Game storage g = games[_gameId];
        require(g.state == GameState.CLOSED, "Game is not yet closed");
        g.hashedSeed = _hashedSeed;
        g.blockNumberToUse = block.number+1;
        g.state = GameState.SPINNING;
    }

    event TwoUpResult(uint gameId, uint result); //CoinResult

    // spinner only, deletes player arrays (should be called within 256 blocks)
    function reviewResults(uint _gameId, bytes32 _seed) public isSpinner(_gameId, msg.sender) {
        Game storage g = games[_gameId];
        require(g.state == GameState.SPINNING);
        require(g.hashedSeed == keccak256(_seed));
        g.hashedSeed = "";
        bytes32 blockHash = blockhash(g.blockNumberToUse);
        uint random = uint(keccak256(uint(_seed) + uint(blockHash)));
        CoinResult result = CoinResult(random % 4);
        emit TwoUpResult(_gameId, uint(result));
        bool newGame = true;
        if (result == CoinResult.HEADSHEADS) {
            payoutWinners(g.heads);
        } else if (result == CoinResult.TAILSTAILS) {
            payoutWinners(g.tails);
        } else {
            newGame = false;
            g.state = GameState.CLOSED; //requires reflip
        }
        if (newGame) {
            g.heads.length = 0;
            g.tails.length = 0;
            g.state = GameState.OPEN;
        }
    }

    function payoutWinners(address[] storage _winners) internal {
        for (uint i=0; i < _winners.length; i++) {
            _winners[i].transfer(AVG_PRICE*2);
        }
    }
}
