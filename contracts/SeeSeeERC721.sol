pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NFT is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public defaultCoverURI;
  uint256 public cost = 0.1 ether;

  struct CCNFTMetadata {
    string coverMediaUri;
    string name;
    uint256 gender;
    string inscription;
    uint256 fatherTokenID;
    uint256 motherTokenID;
    string memoryCollectionUri;
  }
  mapping (uint256 => CCNFTMetadata) CCNFTMetadatas;
  
  mapping (uint256 => bool) coverMediaChangeableMap;
  mapping (uint256 => bool) memoryCollectionChangeableMap;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initDefaultCoverURI
  ) ERC721(_name, _symbol) {
    defaultCoverURI = _initDefaultCoverURI;
  }

  // public
  function mint(
    string memory _coverMediaUri,
    string memory _name,
    uint256 _gender,
    string memory _inscription,
    uint256 _fatherTokenID,
    uint256 _motherTokenID,
    string memory _memoryCollectionUri
  ) public payable {
    if (msg.sender != owner()) {
      require(msg.value >= cost, "You should deposit enough value to mint.");
    }
    uint256 newId = totalSupply() + 1;
    _safeMint(msg.sender, newId);
    CCNFTMetadatas[newId] = CCNFTMetadata(_coverMediaUri,_name,_gender,_inscription,_fatherTokenID,_motherTokenID,_memoryCollectionUri);
    coverMediaChangeableMap[newId] = true;
    memoryCollectionChangeableMap[newId] = true;
  }

  function _baseURI() internal pure override returns(string memory) {
    return "data:application/json;base64,";
  }
  function tokenURI(uint256 tokenId) public view override returns(string memory) {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    CCNFTMetadata memory metadata = CCNFTMetadatas[tokenId];
    string memory imageUri = bytes(metadata.coverMediaUri).length > 1 ? metadata.coverMediaUri : defaultCoverURI;

    // set NFT metadata JSON
    bytes memory metaDataTemplate = (
      abi.encodePacked(
        "{\"name\":\"See See Family - ", metadata.name,
        "\",\"description\":\"Connect Families All Over the World.\",\"image\":\"", imageUri,
        "\",\"external_url\":\"", metadata.memoryCollectionUri,
        "\",\"attributes\":[{\"trait_type\":\"gender\",\"value\":\"", metadata.gender==1?"female":"male",
        "\"},{\"trait_type\":\"inscription\",\"value\":\"", metadata.inscription,
        "\"},{\"trait_type\":\"fatherTokenID\",\"value\":", metadata.fatherTokenID,
        "},{\"trait_type\":\"motherTokenID\",\"value\":\"", metadata.motherTokenID,
        "},],}"
      )
    );
    
    bytes memory metaDataTemplateInBytes = bytes(metaDataTemplate);
    string memory encodedMetada = Base64.encode(metaDataTemplateInBytes);
    
    return (string(abi.encodePacked(_baseURI(), encodedMetada)));
  }

  function getAllInfo(uint256 tokenId) public view returns(CCNFTMetadata memory) {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    return CCNFTMetadatas[tokenId];
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function isCoverMediaChangeable(uint256 tokenId) public view returns (bool) {
    require(
      _exists(tokenId),
      "ERC721Metadata: Boolean query for nonexistent token"
    );
    return coverMediaChangeableMap[tokenId];
  }
  function isMemoryCollectionChangeable(uint256 tokenId) public view returns (bool) {
    require(
      _exists(tokenId),
      "ERC721Metadata: Boolean query for nonexistent token"
    );
    return memoryCollectionChangeableMap[tokenId];
  }
  function freezeCoverMedia(uint256 tokenId) public {
    require(
      _exists(tokenId),
      "ERC721Metadata: Freeze for nonexistent token"
    );
    address nftOwner = ERC721.ownerOf(tokenId);
    require(
      _msgSender() == nftOwner || isApprovedForAll(nftOwner, _msgSender()),
      "ERC721: approve caller is not token owner or approved for all"
    );
    coverMediaChangeableMap[tokenId] = false;
  }
  function freezeMemoryCollection(uint256 tokenId) public {
    require(
      _exists(tokenId),
      "ERC721Metadata: Freeze for nonexistent token"
    );
    address nftOwner = ERC721.ownerOf(tokenId);
    require(
      _msgSender() == nftOwner || isApprovedForAll(nftOwner, _msgSender()),
      "ERC721: approve caller is not token owner or approved for all"
    );
    memoryCollectionChangeableMap[tokenId] = false;
  }

  //only owner  
  function replaceCoverMedia(uint256 tokenId, string memory _coverMediaUri) public onlyOwner {
    require(
      _exists(tokenId),
      "ERC721Metadata: Replace command for nonexistent token"
    );
    require(
      coverMediaChangeableMap[tokenId],
      "ERC721Metadata: Token's cover media is not changeable anymore"
    );
    CCNFTMetadatas[tokenId].coverMediaUri = _coverMediaUri;
    coverMediaChangeableMap[tokenId] = false;
  }
  function replaceMemoryCollection(uint256 tokenId, string memory _memoryCollectionUri) public onlyOwner {
    require(
      _exists(tokenId),
      "ERC721Metadata: Replace command for nonexistent token"
    );
    require(
      memoryCollectionChangeableMap[tokenId],
      "ERC721Metadata: Token's cover media is not changeable anymore"
    );
    CCNFTMetadatas[tokenId].memoryCollectionUri = _memoryCollectionUri;
    memoryCollectionChangeableMap[tokenId] = false;
  }
 
  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }


  //Tracing Family Tree
  function bottomUpTrace(uint256 tokenId) public view returns (string memory) {
    require(
      _exists(tokenId),
      "ERC721Metadata: Trace for nonexistent token"
    );
    address nftOwner = ERC721.ownerOf(tokenId);
    require(
      _msgSender() == nftOwner || isApprovedForAll(nftOwner, _msgSender()),
      "ERC721: approve caller is not token owner or approved for all"
    );
    string memory output = "";
    CCNFTMetadata memory tempMeta = CCNFTMetadatas[tokenId];
    uint256[] memory nextLayerParentBuffer = new uint256[](4);
    uint256[] memory nextLayerBuffer = new uint256[](4);
    for (uint256 i=0; i<4; i++){
      nextLayerParentBuffer[i] = 0;
      nextLayerBuffer[i] = 0;
    }
    nextLayerBuffer[0] = tokenId;
    uint256[] memory layerParentBuffer = new uint256[](4);
    uint256[] memory layerBuffer = new uint256[](4);
    bool end = false;
    while (!end){
      for (uint256 i=0; i<4; i++){
        layerParentBuffer[i] = nextLayerParentBuffer[i];
        layerBuffer[i] = nextLayerBuffer[i];
        nextLayerParentBuffer[i] = 0;
        nextLayerBuffer[i] = 0;
      }
      uint256 nextLayerPointer = 0;
      for (uint256 i=0; i<4; i++){
        uint256 lastId = layerParentBuffer[i];
        uint256 nowId = layerBuffer[i];
        if(nowId==0){
          if(i==0){
            end = true;
          }
          break;
        }
        output = string(abi.encodePacked(output,lastId==0?Strings.toString(nowId):Strings.toString(lastId),"-",Strings.toString(nowId),"|"));
        tempMeta = CCNFTMetadatas[nowId];
        if(tempMeta.fatherTokenID>0){
          nextLayerParentBuffer[nextLayerPointer] = nowId;
          nextLayerBuffer[nextLayerPointer] = tempMeta.fatherTokenID;
          nextLayerPointer += 1;
        }
        if(tempMeta.motherTokenID>0){
          nextLayerParentBuffer[nextLayerPointer] = nowId;
          nextLayerBuffer[nextLayerPointer] = tempMeta.motherTokenID;
          nextLayerPointer += 1;
        }
      }
      output = string(abi.encodePacked(output,"_"));
    }
    return output;
  }
}