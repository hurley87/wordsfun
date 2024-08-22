// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";

library JSONUtils {
    using Strings for uint256;

    function createTokenURI(
        uint256 tokenId,
        string memory letter,
        uint256 points,
        string memory svgImage
    ) internal pure returns (string memory) {
        string memory encodedSvg = Base64.encode(bytes(svgImage));

        // Create JSON metadata
        string memory json = string(abi.encodePacked(
            '{"name":"letter #', tokenId.toString(),
            '","description":"worth ', points.toString(), ' points in words.fun",',
            '"image":"data:image/svg+xml;base64,', encodedSvg, '",',
            '"attributes":[{"trait_type":"Letter","value":"', letter,
            '"},{"trait_type":"Points","value":', points.toString(), '}]}'
        ));

        // Encode JSON metadata to Base64
        string memory encodedJson = Base64.encode(bytes(json));

        // Create final tokenURI
        return string(abi.encodePacked("data:application/json;base64,", encodedJson));
    }
}