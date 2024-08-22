// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library ScrabbleUtils {
    function getScrabbleValue(bytes1 letter) internal pure returns (uint8) {
        bytes memory vowels = "AEIOULNSTR";
        bytes memory twoPoints = "DG";
        bytes memory threePoints = "BCMP";
        bytes memory fourPoints = "FHVWY";
        
        if (contains(vowels, letter)) return 1;
        if (contains(twoPoints, letter)) return 2;
        if (contains(threePoints, letter)) return 3;
        if (contains(fourPoints, letter)) return 4;
        if (letter == 'K') return 5;
        if (letter == 'J' || letter == 'X') return 8;
        if (letter == 'Q' || letter == 'Z') return 10;
        revert("Invalid letter");
    }

    function contains(bytes memory haystack, bytes1 needle) internal pure returns (bool) {
        for (uint i = 0; i < haystack.length; i++) {
            if (haystack[i] == needle) return true;
        }
        return false;
    }
}