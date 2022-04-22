// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {LibDiamond} from "./LibDiamond.sol";

struct Tile {
    bool isActive;
    uint256 tokenId;
    address winner;
}

struct Match {
    address player1;
    address player2;
    bool player2Turn;
    uint256[5] player1Gotchis;
    uint256[5] player2Gotchis;
    uint256 lastMovePlayer1;
    uint256 lastMovePlayer2;
    Tile[3][3] grid;
}

struct Register {
    address player;
    uint256[5] tokenIds;
}

struct AppStorage {
    address aavegotchiDiamond;
    mapping(uint256 => Match) matches;
    uint256 nextId;
    Register[] register;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

contract Modifiers {
    AppStorage internal s;

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }
}
