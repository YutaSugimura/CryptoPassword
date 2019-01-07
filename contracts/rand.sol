pragma solidity ^0.5.0;

contract Rand {
  uint256 private seed;


  constructor() public {
    seed = getRand();
  }

  function getRand() private view returns(uint256) {
    uint256 randNumber = uint256(keccak256(abi.encodePacked(
      seed,
      now,
      block.number,
      msg.sender
    )));
    return randNumber;
  }

  function easyRand() view private returns(uint256) {
    return uint256(keccak256(abi.encodePacked(seed)));
  }

  function updateSeed() internal returns(uint256) {
    uint256 randNumber = getRand();
    seed = randNumber;
    return randNumber %= (10 ** 6);
  }

  function easyUpdateSeed() internal returns(uint256) {
    uint256 randNumber = easyRand();
    seed = randNumber;
    return randNumber %= (10 ** 4);
  }
  
}
