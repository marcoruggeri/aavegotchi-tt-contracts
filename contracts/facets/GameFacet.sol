// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {AppStorage, Modifiers} from "../libraries/AppStorage.sol";
import "../interfaces/IAavegotchiDiamond.sol";

contract GameFacet is Modifiers {
    function register(uint256[5] tokenIds) external {
        for (uint256 i; i < 5; i++) {
            require(
                IAavegotchiDiamond(s.aavegotchiDiamond).ownerOf(_tokenIds[i]) ==
                    msg.sender,
                "GameFacet: not owner"
            );
        }
        register.push(Register(msg.sender, _tokenIds));
        if (register.length == 2) {
            _createMatch(
                register[0].player,
                msg.sender,
                register[0].tokenIds,
                _tokenIds
            );
            register.pop();
            register.pop();
        }
    }

    function _createMatch(
        address player1,
        address player2,
        uint256[5] player1Ids,
        uint256[5] player2Ids
    ) internal {
        Match memory newMatch = Match(player1, player2, player1Ids, player2Ids);
        matches[s.nextId] = newMatch;
        nextId++;
        block.timestamp;
        block.timestamp;
    }

    function playCard(
        uint256 tokenId,
        uint256 matchId,
        uint256 x,
        uint256 y
    ) external {
        if (!matches[matchId].isPlayer2Turn) {
            require(
                msg.sender == matches[matchId].player1,
                "GameFacet: not player 1"
            );
        } else {
            require(
                msg.sender == matches[matchId].player2,
                "GameFacet: not player 2"
            );
        }
        require(x != 0 && x < 3, "GameFacet: wrong x");
        require(y != 0 && y < 3, "GameFacet: wrong y");
        require(
            !matches[matchId].grid[x][y].isActive,
            "GameFacet: wrong coords"
        );
        // check around
        int16[6] memory playerGotchiParams = IAavegotchiDiamond(
            s.aavegotchiDiamond
        ).getAavegotchi(tokenId).modifiedNumericTraits;
        int16[6] memory oppositeGotchiParams;
        if (
            y - 1 >= 0 &&
            matches[matchId].grid[x][y - 1].isActive &&
            matches[matchId].grid[x][y - 1].winner != msg.sender
        ) {
            uint256 oppositeTokenId = matches[matchId].grid[x][y - 1].tokenId;
            oppositeGotchiParams = IAavegotchiDiamond(s.aavegotchiDiamond)
                .getAavegotchi(oppositeTokenId)
                .modifiedNumericTraits;
            if (playerGotchiParams[0] > oppositeGotchiParams[2]) {
                matches[matchId].grid[x][y - 1].winner = msg.sender;
            }
        }
        if (
            x - 1 >= 0 &&
            matches[matchId].grid[x - 1][y].isActive &&
            matches[matchId].grid[x - 1][y].winner != msg.sender
        ) {
            uint256 oppositeTokenId = matches[matchId].grid[x - 1][y].tokenId;
            oppositeGotchiParams = IAavegotchiDiamond(s.aavegotchiDiamond)
                .getAavegotchi(oppositeTokenId)
                .modifiedNumericTraits;
            if (playerGotchiParams[3] > oppositeGotchiParams[1]) {
                matches[matchId].grid[x - 1][y].winner = msg.sender;
            }
        }
        if (
            y + 1 < 3 &&
            matches[matchId].grid[x][y + 1].isActive &&
            matches[matchId].grid[x][y + 1].winner != msg.sender
        ) {
            uint256 oppositeTokenId = matches[matchId].grid[x][y + 1].tokenId;
            oppositeGotchiParams = IAavegotchiDiamond(s.aavegotchiDiamond)
                .getAavegotchi(oppositeTokenId)
                .modifiedNumericTraits;
            if (playerGotchiParams[2] > oppositeGotchiParams[0]) {
                matches[matchId].grid[x][y + 1].winner = msg.sender;
            }
        }
        if (
            x + 1 < 3 &&
            matches[matchId].grid[x + 1][y].isActive &&
            matches[matchId].grid[x + 1][y].winner != msg.sender
        ) {
            uint256 oppositeTokenId = matches[matchId].grid[x + 1][y].tokenId;
            oppositeGotchiParams = IAavegotchiDiamond(s.aavegotchiDiamond)
                .getAavegotchi(oppositeTokenId)
                .modifiedNumericTraits;
            if (playerGotchiParams[1] > oppositeGotchiParams[3]) {
                matches[matchId].grid[x + 1][y].winner = msg.sender;
            }
        }
        // ok
        matches[matchId].grid[x][y].isActive = true;
        matches[matchId].grid[x][y].tokenId = tokenId;
        matches[matchId].grid[x][y].winner = msg.sender;
    }

    function checkWinner(uint256 matchId) internal returns (address winner) {
        uint256 player1Points;
        uint256 player2Points;
        for (uint256 i; i < 3; i++) {
            for (uint256 j; j < 3; j++) {
                if (
                    s.matches[matchId].grid[i][j].winner ==
                    s.matches[matchId].player1
                ) player1Points++;
                else if (
                    s.matches[matchId].grid[i][j].winner ==
                    s.matches[matchId].player2
                ) player2Points++;
            }
        }
        if (player1Points > player2Points && player1Points > 5)
            return s.matches[matchId].player1;
        else return s.matches[matchId].player2;
    }
}

// player1 5 6
// player2 4 5
