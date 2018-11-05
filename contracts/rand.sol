pragma solidity 0.4.24;

contract Rand {

  uint256 private randSeed = 1;

  mapping(address => uint256[]) internal randToAddress;

  function _rand() private view returns(uint256) {
    uint256 rand = uint256(sha3(now, block.number, randSeed));

    return rand %= (10 ** 6);
  }

  function _updateSeed() internal {
    randSeed = _rand();
  }

  function viewRand() public view returns(uint256) {
    return randToAddress[msg.sender];
  }

}