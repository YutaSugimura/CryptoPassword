pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import "./pinStorage.sol";
import "./rand.sol";

contract passwordEscrow is Ownable, Rand, PinStorage {
  using SafeMath for uint256;

  uint256 public commissionFee;
  uint256 public totalFee;

  struct Transfer {
    address from;
    uint256 amount;
  }

  mapping(bytes32 => Transfer) private password;

  event LogDeposit(address indexed from, uint256 amount);
  event LogGetTransfer(address indexed from, address indexed recipient, uint256 amount);

  constructor(uint256 _fee) public {
    commissionFee = _fee;
  }

  function withdraw() public payable onlyOwner {
    msg.sender.transfer(address(this).balance);
  }

  function withdrawFee() public payable onlyOwner {
    require( totalFee > 0);

    uint256 fee = totalFee;
    totalFee = 0;

    msg.sender.transfer(fee);
  }

  function changeCommissionFee(uint256 _fee) public onlyOwner {
    commissionFee = _fee;
  }

  function deposit(bytes32 _password) public payable {
    require(msg.value > commissionFee);

    uint256 pin = updateSeed();
    bytes32 _pin = bytes32(pin);
    bytes32 pass = keccak256(abi.encodePacked(_password, _pin));

    require(password[pass].amount == 0);

    setPin(pin);
    password[pass].from = msg.sender;
    password[pass].amount = password[pass].amount.add(msg.value);

    emit LogDeposit(msg.sender, msg.value);
  }

  function getTransfer(bytes32 _password, uint256 _pin) public {

    bytes32 pass = keccak256(abi.encodePacked(_password, _pin));
    require(password[pass].amount > 0);

    address from = password[pass].from;
    uint256 amount = password[pass].amount;
    amount = amount.sub(commissionFee);
    totalFee = totalFee.add(commissionFee);

    password[pass].amount = 0;

    msg.sender.transfer(amount);

    emit LogGetTransfer(from, msg.sender, amount);
  }

}