// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";

library LibraryColors {
    using Strings for uint256;

    function getBackgroundColors() internal pure returns (string[7] memory) {
        return [
            "#dbeafe", "#f3e8ff", "#fce7f3", "#ffedd5", "#dcfce7", "#fef9c3", "#f3f4f6"
        ];
    }

    function getBorderColors() internal pure returns (string[7] memory) {
        return [
            "#3b82f6", "#a855f7", "#ec4899", "#f97316", "#22c55e", "#eab308", "#6b7280"
        ];
    }

    function getLetterColors() internal pure returns (string[7] memory) {
        return [
            "#172554", "#3b0764", "#500724", "#431407", "#052e16", "#422006", "#030712"
        ];
    }

    function getColorsLength() public pure returns (uint256) {
        return 7; // Since all color arrays have 7 elements
    }

    function getColors(uint256 index) public pure returns (string memory, string memory, string memory) {
        require(index < 7, "Index out of bounds");
        return (getLetterColors()[index], getBackgroundColors()[index], getBorderColors()[index]);
    }

    function generateSVG(
        string memory letterColor,
        string memory backgroundColor,
        string memory borderColor,
        string memory letter,
        uint256 points
    ) public pure returns (string memory) {
        string memory animateColor = points > 9 ? borderColor : letterColor;
        string memory animateFontSize = points > 9 ? "90px" : "96px";
        string memory svgStart = string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200">',
            '<style>@import url("https://fonts.googleapis.com/css2?family=Geologica:wght@100..900"); .geo-font { font-family: "Geologica", sans-serif; font-weight: bold; }</style>',
            '<rect x="0" y="0" width="200" height="200" rx="15" ry="15" fill="', borderColor, '"/>',
            '<rect x="5" y="0" width="195" height="195" rx="10" ry="10" fill="', backgroundColor, '"/>'
        ));
        string memory svgEnd = string(abi.encodePacked(
            '<text x="93%" y="13%" text-anchor="end" fill="', letterColor, '" font-size="20" font-weight="bold" font-family="Geologica" class="geo-font">', points.toString(), '</text>',
            '</svg>'
        ));

        return string(abi.encodePacked(
            svgStart,
            '<text x="50%" y="50%" text-anchor="middle" fill="', letterColor, '" dy=".3em" font-size="96" font-weight="bold" font-family="Geologica" class="geo-font">', 
            '<animate attributeName="fill" values="', animateColor, ';', letterColor, ';', animateColor, '" dur="2s" repeatCount="indefinite"  />',
            '<animate attributeName="font-size" values="', animateFontSize, ';96px;', animateFontSize, '" dur="2s" repeatCount="indefinite"  />',
            letter, 
            '</text>',
            svgEnd
        ));
    }
}