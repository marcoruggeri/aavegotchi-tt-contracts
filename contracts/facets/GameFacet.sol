// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {AppStorage, Modifiers, Match, Register, Tile} from "../libraries/AppStorage.sol";
import "../interfaces/IAavegotchiDiamond.sol";

contract GameFacet is Modifiers {
    function register(uint256[5] calldata tokenIds) external {
        for (uint256 i; i < 5; i++) {
            require(
                IAavegotchiDiamond(s.aavegotchiDiamond).ownerOf(tokenIds[i]) ==
                    msg.sender,
                "GameFacet: not owner"
            );
        }
        s.registered.push(Register(msg.sender, tokenIds));
        if (s.registered.length == 2) {
            _createMatch(
                s.registered[0].player,
                msg.sender,
                s.registered[0].tokenIds,
                tokenIds
            );
            s.registered.pop();
            s.registered.pop();
        }
    }

    function _createMatch(
        address player1,
        address player2,
        uint256[5] memory player1Ids,
        uint256[5] memory player2Ids
    ) internal {
        Match memory newMatch = Match(
            player1,
            player2,
            false,
            player1Ids,
            player2Ids,
            0
        );
        s.matches[s.nextId] = newMatch;
        s.nextId++;
    }

    function playCard(
        uint256 tokenId,
        uint256 matchId,
        uint256 x,
        uint256 y
    ) external {
        if (!s.matches[matchId].player2Turn) {
            require(
                msg.sender == s.matches[matchId].player1,
                "GameFacet: not player 1"
            );
        } else {
            require(
                msg.sender == s.matches[matchId].player2,
                "GameFacet: not player 2"
            );
        }
        require(x != 0 && x < 3, "GameFacet: wrong x");
        require(y != 0 && y < 3, "GameFacet: wrong y");
        require(!s.grids[matchId][x][y].isActive, "GameFacet: wrong coords");
        // check around
        int16[6] memory playerGotchiParams = IAavegotchiDiamond(
            s.aavegotchiDiamond
        ).getAavegotchi(tokenId).modifiedNumericTraits;
        int16[6] memory oppositeGotchiParams;
        if (
            y - 1 >= 0 &&
            s.grids[matchId][x][y - 1].isActive &&
            s.grids[matchId][x][y - 1].winner != msg.sender
        ) {
            uint256 oppositeTokenId = s.grids[matchId][x][y - 1].tokenId;
            oppositeGotchiParams = IAavegotchiDiamond(s.aavegotchiDiamond)
                .getAavegotchi(oppositeTokenId)
                .modifiedNumericTraits;
            if (playerGotchiParams[0] > oppositeGotchiParams[2]) {
                s.grids[matchId][x][y - 1].winner = msg.sender;
            }
        }
        if (
            x - 1 >= 0 &&
            s.grids[matchId][x - 1][y].isActive &&
            s.grids[matchId][x - 1][y].winner != msg.sender
        ) {
            uint256 oppositeTokenId = s.grids[matchId][x - 1][y].tokenId;
            oppositeGotchiParams = IAavegotchiDiamond(s.aavegotchiDiamond)
                .getAavegotchi(oppositeTokenId)
                .modifiedNumericTraits;
            if (playerGotchiParams[3] > oppositeGotchiParams[1]) {
                s.grids[matchId][x - 1][y].winner = msg.sender;
            }
        }
        if (
            y + 1 < 3 &&
            s.grids[matchId][x][y + 1].isActive &&
            s.grids[matchId][x][y + 1].winner != msg.sender
        ) {
            uint256 oppositeTokenId = s.grids[matchId][x][y + 1].tokenId;
            oppositeGotchiParams = IAavegotchiDiamond(s.aavegotchiDiamond)
                .getAavegotchi(oppositeTokenId)
                .modifiedNumericTraits;
            if (playerGotchiParams[2] > oppositeGotchiParams[0]) {
                s.grids[matchId][x][y + 1].winner = msg.sender;
            }
        }
        if (
            x + 1 < 3 &&
            s.grids[matchId][x + 1][y].isActive &&
            s.grids[matchId][x + 1][y].winner != msg.sender
        ) {
            uint256 oppositeTokenId = s.grids[matchId][x + 1][y].tokenId;
            oppositeGotchiParams = IAavegotchiDiamond(s.aavegotchiDiamond)
                .getAavegotchi(oppositeTokenId)
                .modifiedNumericTraits;
            if (playerGotchiParams[1] > oppositeGotchiParams[3]) {
                s.grids[matchId][x + 1][y].winner = msg.sender;
            }
        }
        // ok
        s.grids[matchId][x][y].isActive = true;
        s.grids[matchId][x][y].tokenId = tokenId;
        s.grids[matchId][x][y].winner = msg.sender;
        s.matches[matchId].movsCounter++;

        if (s.matches[matchId].movsCounter == 9) {
            checkWinner(matchId);
        }
    }

    function checkWinner(uint256 matchId)
        internal
        view
        returns (address winner)
    {
        uint256 player1Points;
        uint256 player2Points;
        for (uint256 i; i < 3; i++) {
            for (uint256 j; j < 3; j++) {
                if (s.grids[matchId][i][j].winner == s.matches[matchId].player1)
                    player1Points++;
                else if (
                    s.grids[matchId][i][j].winner == s.matches[matchId].player2
                ) player2Points++;
            }
        }
        if (player1Points > player2Points && player1Points > 5)
            return s.matches[matchId].player1;
        else return s.matches[matchId].player2;
    }

    function getGrid(uint256 matchId)
        external
        view
        returns (Tile[3][3] memory)
    {
        return s.grids[matchId];
    }

    function setAddresses(address _aavegotchiDiamond) external onlyOwner {
        s.aavegotchiDiamond = _aavegotchiDiamond;
    }
}
