// SPDX-License-Identifier: GPL 3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

contract NiftySwap {

  /// @dev The contract's primary NFT collection.
  IERC721Metadata public nifty;

  /// @dev Token ID of NFT to trade => Token ID of NFT wanted => Interested in trade.
  mapping(uint => mapping(uint => bool)) public interestInTrade;

  /// @dev Token ID of NFT to trade => Token ID of NFT wanted => owner of NFT to trade.
  mapping(uint => mapping(uint => address)) public ownerAtSignal;

  constructor(address _nifty) {
    nifty = IERC721Metadata(_nifty);
  }

  event InterestInTrade(uint indexed tokenIdOfWanted, uint indexed tokenIdToTrade, address indexed trader);
  event Trade(address ownerOfNft1, uint indexed tokenId1, address ownerOfNft2, uint indexed tokenId2);

  /// @dev Signal interest to trade an NFT you own for an NFT you want. If both parties signal interest, the NFTs are swapped.
  function signalInterest(uint _tokenIdNftWanted, uint _tokenIdNftToTrade, bool _interest) external {
    require(
      nifty.ownerOf(_tokenIdNftToTrade) == msg.sender, 
      "NiftySwap: Cannot signal interest to trade an NFT you do not own."
    );

    require(
      nifty.getApproved(_tokenIdNftToTrade) == address(this) ||
      
      nifty.isApprovedForAll(msg.sender, address(this)),
      "NiftySwap: This contract is no longer approved to transfer the NFT wanted."
    );

    if(interestInTrade[_tokenIdNftWanted][_tokenIdNftToTrade] && _interest) {

      address ownerOfWanted = nifty.ownerOf(_tokenIdNftWanted);

      require(
        ownerAtSignal[_tokenIdNftWanted][_tokenIdNftToTrade] == ownerOfWanted,
        "NiftySwap: The owner of the NFT you wanted has changed."
      );

      trade(_tokenIdNftWanted, _tokenIdNftToTrade, msg.sender);

    } else {

      interestInTrade[_tokenIdNftToTrade][_tokenIdNftWanted] = _interest;
      ownerAtSignal[_tokenIdNftToTrade][_tokenIdNftWanted] = msg.sender;

      emit InterestInTrade(_tokenIdNftWanted, _tokenIdNftToTrade, msg.sender);

    }
  }

  /// @dev Trades one NFT for another.
  function trade(uint _tokenIdNftWanted, uint _tokenIdNftToTrade, address _ownerOfNftToTrade) internal {

    // Get owner of NFT wanted.
    address ownerOfNftWanted = nifty.ownerOf(_tokenIdNftWanted);

    // Transfer NFT to trade.
    nifty.transferFrom(
      _ownerOfNftToTrade,
      ownerOfNftWanted,
      _tokenIdNftToTrade
    );

    // Transfer NFT wanted.
    nifty.transferFrom(
      ownerOfNftWanted,
      _ownerOfNftToTrade,
      _tokenIdNftWanted
    );

    emit Trade(_ownerOfNftToTrade, _tokenIdNftToTrade, ownerOfNftWanted, _tokenIdNftWanted);
  }
}