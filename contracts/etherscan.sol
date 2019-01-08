
pragma solidity ^0.5.0;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// File: contracts/pinStorage.sol

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

// File: contracts/rand.sol

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

// File: contracts/passwordEscrow.sol

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
