//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";
import {IVRFCoordinatorV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./ScrabbleUtils.sol";
import "./JSONUtils.sol";

interface ILibraryColors {
    function getColorsLength() external view returns (uint256);
    function getColors(uint256 index) external view returns (string memory, string memory, string memory);
    function getColorName(uint256 index) external view returns (string memory);
    function generateSVG(string memory letterColor, string memory backgroundColor, string memory borderColor, string memory letter, uint256 points) external view returns (string memory);
}

contract WordsFun is ERC721Enumerable, ERC721URIStorage, VRFConsumerBaseV2Plus {
    using Strings for uint256;
    using Counters for Counters.Counter;
    using JSONUtils for uint256;
    Counters.Counter private _tokenIds;
    ILibraryColors public colors;
    string private constant scrabbleLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

    struct VRFConfig {
        uint256 subscriptionId;
        bytes32 keyHash;
        uint32 callbackGasLimit;
        uint16 requestConfirmations;
    }
    VRFConfig private s_vrfConfig;

    event NFTsMinted(address indexed minter, uint256 amount, uint256[] tokenIds);

    address immutable vrfCoordinator = 0x5C210eF41CD1a72de73bF76eC39637bB0d3d7BEE;
    mapping(uint256 => uint256) private s_requestIdToTokenId;
    mapping(uint256 => uint256) private s_tokenIdToRandomWord;
    mapping(uint256 => uint256[]) private s_requestIdToTokenIds;

    event RequestedRandomness(uint256 indexed requestId, uint256 indexed tokenId);
    event ReceivedRandomness(uint256 indexed requestId, uint256 indexed tokenId, uint256 randomWord);

    constructor(uint256 subscriptionId, address _colors) ERC721("WordsFun", "FUN") VRFConsumerBaseV2Plus(vrfCoordinator) {
        s_vrfConfig = VRFConfig({
            subscriptionId: subscriptionId,
            keyHash: 0x9e1344a1247c8a1785d0a4681a27152bffdb43666ae5bf7d14d24a5efd44bf71,
            callbackGasLimit: 2500000,
            requestConfirmations: 3
        });
        colors = ILibraryColors(_colors);
    }

    function mintNFT() public payable {
        _mintInternal(1);
    }

	function mintNFTs(uint256 amount) public payable {
		_mintInternal(amount);
	}

    function _mintInternal(uint256 amount) internal {
        require(msg.value >= 0.001 ether * amount, "Insufficient payment");

        uint256[] memory newTokenIds = new uint256[](amount);
        for (uint256 i = 0; i < amount; i++) {
            _tokenIds.increment();
            uint256 newTokenId = _tokenIds.current();
            _safeMint(msg.sender, newTokenId);
            newTokenIds[i] = newTokenId;
        }

        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: s_vrfConfig.keyHash,
                subId: s_vrfConfig.subscriptionId,
                requestConfirmations: s_vrfConfig.requestConfirmations,
                callbackGasLimit: s_vrfConfig.callbackGasLimit,
                numWords: uint32(amount),
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
            })
        );
        s_requestIdToTokenIds[requestId] = newTokenIds;
        emit RequestedRandomness(requestId, newTokenIds[0]);
        emit NFTsMinted(msg.sender, amount, newTokenIds);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        uint256[] memory tokenIds = s_requestIdToTokenIds[requestId];
        require(tokenIds.length == randomWords.length, "Mismatch in random words and token IDs");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            s_tokenIdToRandomWord[tokenId] = randomWords[i];

            // Generate token URI components
            string memory letter = _randomLetter(tokenId);
            uint256 points = _getPoints(tokenId);
            string memory svgImage = _generateSVG(tokenId);

            // Create and set the token URI using the new library
            string memory finalTokenURI = tokenId.createTokenURI(letter, points, svgImage);
            _setTokenURI(tokenId, finalTokenURI);

            emit ReceivedRandomness(requestId, tokenId, randomWords[i]);
        }
    }

    function _randomLetter(uint256 tokenId) internal view returns (string memory) {
        require(s_tokenIdToRandomWord[tokenId] != 0, "Randomness not received yet");
        uint256 randomIndex = s_tokenIdToRandomWord[tokenId] % bytes(scrabbleLetters).length;
        bytes1 letterByte = bytes(scrabbleLetters)[randomIndex];
        return string(abi.encodePacked(letterByte));
    }

    function _randomMultiplier(uint256 tokenId) internal view returns (uint256) {
        require(s_tokenIdToRandomWord[tokenId] != 0, "Randomness not received yet");
        uint256 randomNumber = s_tokenIdToRandomWord[tokenId] % 100;

        if (randomNumber < 95) {
            return (randomNumber % 3) + 1; // 1, 2, or 3 with 95% probability
        } else {
            return 4; // 5% chance for 4x
        }
    }

    function _randomColor(uint256 tokenId) internal view returns (string memory, string memory, string memory) {
        require(s_tokenIdToRandomWord[tokenId] != 0, "Randomness not received yet");
        uint256 randomIndex = s_tokenIdToRandomWord[tokenId] % colors.getColorsLength();
        return colors.getColors(randomIndex);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function _getColorName(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "not exist");
        bytes32 randomHash = keccak256(abi.encodePacked(block.prevrandao, tokenId));
        uint256 randomIndex = uint256(uint8(randomHash[2])) % colors.getColorsLength();
        return colors.getColorName(randomIndex);
    }

    function _getScrabbleValue(bytes1 letter) internal pure returns (uint8) {
        return ScrabbleUtils.getScrabbleValue(letter);
    }

    function _getPoints(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "not exist");
        string memory letter = _randomLetter(tokenId);
        uint256 multiplier = _randomMultiplier(tokenId);
        uint256 scrabbleValue = _getScrabbleValue(bytes(letter)[0]);
        return scrabbleValue * multiplier;
    }

    function _generateSVG(uint256 tokenId) internal view returns (string memory) {
        (string memory letterColor, string memory backgroundColor, string memory borderColor) = _randomColor(tokenId);
        string memory letter = _randomLetter(tokenId);
        uint256 points = _getPoints(tokenId);
       
        return colors.generateSVG(letterColor, backgroundColor, borderColor, letter, points);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
}