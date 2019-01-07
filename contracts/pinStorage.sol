pragma solidity ^0.5.0;


contract PinStorage {

  // address => count
  mapping(address => uint256) private countToAddress;

  mapping(address => mapping(uint256 => uint256)) private pinToAddress;

  function setPin(uint256 _pin) internal {
    uint256 index = countToAddress[msg.sender];
    countToAddress[msg.sender]++;
    pinToAddress[msg.sender][index] = _pin;
  }

  function getPin() public view returns(uint256) {
    return pinToAddress[msg.sender][
      countToAddress[msg.sender] - 1
    ];
  }

  function getThreePins() public view returns(uint256, uint256, uint256) {
    uint256 num1 =  pinToAddress[msg.sender][countToAddress[msg.sender] - 1];
    uint256 num2 =  pinToAddress[msg.sender][countToAddress[msg.sender] - 2];
    uint256 num3 =  pinToAddress[msg.sender][countToAddress[msg.sender] - 3];

    return(num1, num2, num3);
  }
}