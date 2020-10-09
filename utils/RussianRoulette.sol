pragma solidity >= 0.6.0 < 0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./Interfaces.sol";
import "./GameController.sol";
import { GambolrUtils } from "./GambolrUtils.sol";

contract RussianRoulette is GameController, Pausable {
    using SafeMath for uint256;

    uint256 constant public FEE_PERCENT1 = 10 ** 16; // 1%

    struct Game {
        uint256 id;
        address payable player;
        uint256 bet;
        uint256 cards;
    }

    struct GamesRequests {
        mapping(uint256 => Game) games; // index -> game
        uint256 headIndex;
        uint256 tailIndex;
    }

    event RussianRouletteResult(uint256 indexed id, address indexed player, bool win, uint256 requestId, uint256 gameIndex);

    IPool internal _poolController;

    mapping(uint256 => GamesRequests) internal requests; // requestId -> games

    uint256 internal _numberOfPublishedGames;

    constructor (address oracleAddress, address poolControllerAddress) GameController(oracleAddress) public {
        _setPoolController(poolControllerAddress);
        _numberOfPublishedGames = 10;
        _pause();
    }

    function setPoolController(address poolControllerAddress) onlyOwner external {
        _setPoolController(poolControllerAddress);
    }

    function setNumberOfPublishedGames(uint256 numberOfPublishedGames) external onlyOwner {
        _numberOfPublishedGames = numberOfPublishedGames;
    }

    function getNumberOfPublishedGames() external view returns (uint256) {
        return _numberOfPublishedGames;
    }

    function getRequestInfo(uint256 requestId) external view onlyOwner returns (uint256, uint64, Status, uint256) {
        return (
            _randomNumbers[requestId].result,
            _randomNumbers[requestId].timestamp,
            _randomNumbers[requestId].status,
            requests[requestId].tailIndex
        );
    }

    function getGameInfo(uint256 requestId, uint256 index) external view returns (uint256, address, uint256, uint256) {
        require(index < requests[requestId].tailIndex, "index out of range");
        Game memory game = requests[requestId].games[index];
        return (
            game.id,
            game.player,
            game.bet,
            game.cards,
        );
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function play(uint256 betId, uint256 betAmount, uint256 cards) external whenNotPaused payable {
        // require(cylinderSize >= 2 && cylinderSize <= 100, "incorrect cylinderSize");
        // require(bulletsNumber >= 1 && bulletsNumber < cylinderSize, "incorrect bulletsNumber");
        uint256 gasFee = _poolController.getOracleGasFee();
        
        require(betAmount >= gasFee, "incorrectly small bet");
        require(msg.value >= betAmount, "incorrectly small bet");
        // TODO: ask polina about maxbet logic
        uint256 maxWin = _poolController.maxBet(50 * (10 ** 16)); // 0.5 * 10^18 (50%)
        uint256 potentialWin = betAmount.mul(2);
        require(potentialWin <= maxWin, "incorrectly large bet");
        
        _poolController.addBetToPool{callValue: msg.value}(betAmount);
        if (_randomNumbers[_lastRequestId].status != Status.Pending) {
            super._updateRandomNumber();
        }
        GamesRequests storage request = requests[_lastRequestId];
        request.games[request.tailIndex] = Game(betId, _msgSender(), betAmount, cards);
        request.tailIndex = request.tailIndex.add(1);
    }

    function manualPublishResults(uint256 requestId, uint256 numberOfGames) external whenNotPaused {
        require(_randomNumbers[requestId].status == Status.Result, "waiting a random number");
        uint256 randomNumber = _randomNumbers[requestId].result;
        _calculateResults(randomNumber, requestId, numberOfGames);
    }

    function _publishResults(uint256 randomNumber, uint256 requestId) internal override {
        _calculateResults(randomNumber, requestId, _numberOfPublishedGames);
    }

    function _calculateResults(uint256 randomNumber, uint256 requestId, uint256 numberOfGames) internal {
        uint256 tailIndex = requests[requestId].tailIndex;
        uint256 counter = 0;
        for (uint256 index = requests[requestId].headIndex; index < tailIndex && counter < numberOfGames; index = index.add(1)) {
            Game memory currentGame = requests[requestId].games[index];
            // TODO: сreate win loose logic
            uint256 winCondition = randomNumber % currentGame.cylinderSize;
            if (winCondition >= currentGame.bulletsNumber) {
                uint256 gasFee = _poolController.getOracleGasFee(currentGame.tokenAddress);
                uint256 winAmount = currentGame.bet.mul(currentGame.cylinderSize).div(currentGame.cylinderSize.sub(currentGame.bulletsNumber)); // bet * cylinderSize / (cylinderSize - bulletsNumber)
                // TODO: сasino commission
                winAmount = winAmount.sub(winAmount.mul(FEE_PERCENT1).div(GambolrUtils.PERCENT100)).sub(gasFee);
                if (_poolController.rewardDisribution(currentGame.player, winAmount) == false) {
                    requests[requestId].headIndex = index;
                    return;
                }
                emit RussianRouletteResult(currentGame.id, currentGame.player, true, requestId, index);
            } else {
                emit RussianRouletteResult(currentGame.id, currentGame.player, false, requestId, index);
            }
            counter = counter.add(1);
        }
        requests[requestId].headIndex = tailIndex;
    }

    function _setPoolController(address poolAddress) internal {
        IPool poolCandidate = IPool(poolAddress);
        require(poolCandidate.supportsIPool(), "poolAddress must be IPool");
        _poolController = poolCandidate;
    }
}
