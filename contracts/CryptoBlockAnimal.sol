// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


interface IDescriptors {
    function tokenURI(uint256 tokenId, CryptoBlockAnimal animalColoringBook) external view returns(string memory);
}

interface IMintableBurnable {
    function mint(address mintTo) external;
    function burn(uint256 tokenId) external;
}

interface IGTAP1 {
    function copyOf(uint256 tokenId) external returns(uint256);
}

struct Animal {
    uint8 animalType;
    uint8 mood;
}



// types = cat = 1, bunny  = 2, mouse = 3, skull = 4, unicorn = 5, creator = 6 

contract CryptoBlockAnimal is ERC721Enumerable, Ownable {
    IDescriptors public immutable descriptors;
    uint256 public immutable mintFeeWei = 1e17;
    uint256 public immutable maxNonOGCount = 1000;
    uint256 private _nonce;

    mapping(uint256 => Animal) public animalInfo;
    mapping(uint256 => address[]) private _transferHistory;
    // Can mint 1 per GTAP1 OG
    mapping(uint256 => uint256) public ogMintCount;
    // each GTAP1 holder can mint 2
    mapping(address => uint256) public gtapHolderMintCount;

    constructor(address _owner, IDescriptors _descriptors) ERC721("Crypto Block Animal", "GTAP2") {
        transferOwnership(_owner);
        descriptors = _descriptors;
    }
    
    function getMintPrice()public view returns(uint256){
        return mintFeeWei;
    }

    function transferHistory(uint256 tokenId) external view returns (address[] memory){
        return _transferHistory[tokenId];
    }

    function mint(address mintTo) payable external {
        uint256 mintFee = mintFeeWei;
        require(msg.value >= mintFee, "CryptoBlockAnimal: fee too low");
        require(_nonce < maxNonOGCount, 'CryptoBlockAnimal: minting closed');
        _mint(mintTo);
    }


    function _mint(address mintTo) private {
        require(_nonce < 1000, 'BlockAnimal: reached max mint');
        _safeMint(mintTo, ++_nonce, "");

        uint256 randomNumber = _randomishIntLessThan("animal", 101);
        uint8 animalType = (
         (randomNumber < 31 ? 1 :
          (randomNumber < 56 ? 2 :
           (randomNumber < 76 ? 3 :
            (randomNumber < 91 ? 4 :
             (randomNumber < 99 ? 5 : 6))))));
        
        animalInfo[_nonce].animalType = animalType;
    }



    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        super.transferFrom(from, to, tokenId);
         if(_transferHistory[tokenId].length < 4) {
            _transferHistory[tokenId].push(to);
            if(_transferHistory[tokenId].length == 4){
                uint8 random = _randomishIntLessThan("mood", 10) + 1;
                animalInfo[tokenId].mood = random > 6  ? 1 : random;
            }
        }
    }
    
    
    function tokenURI(uint256 tokenId) public override view returns(string memory) {
        return descriptors.tokenURI(tokenId, this);
    }


    function _randomishIntLessThan(bytes32 salt, uint8 n) private view returns (uint8) {
        if (n == 0)
            return 0;
        return uint8(keccak256(abi.encodePacked(block.timestamp, _nonce, msg.sender, salt))[0]) % n;
    }

    function payOwner(address to, uint256 amount) public onlyOwner() {
        require(amount <= address(this).balance, "amount too high");
        payable(to).transfer(amount);
    }
    
}





