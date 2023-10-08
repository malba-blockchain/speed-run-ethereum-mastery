// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract Streamer is Ownable {
  event Opened(address, uint256);
  event Challenged(address);
  event Withdrawn(address, uint256);
  event Closed(address);

  mapping(address => uint256) balances;
  mapping(address => uint256) canCloseAt;

  function fundChannel() public payable {
    /*
      Checkpoint 2: fund a channel

      Complete this function so that it:
      - reverts if msg.sender already has a running channel (ie, if balances[msg.sender] != 0)
      - updates the balances mapping with the eth received in the function call
      - emits an Opened event
    */

    require(balances[msg.sender] == 0, "The sender already has a running channel");

    balances[msg.sender] += msg.value;

    emit Opened(msg.sender, msg.value);
  }

  function timeLeft(address channel) public view returns (uint256) {
    if (canCloseAt[channel] == 0 || canCloseAt[channel] < block.timestamp) {
      return 0;
    }

    return canCloseAt[channel] - block.timestamp;
  }

  function withdrawEarnings(Voucher calldata voucher) onlyOwner public {
    // like the off-chain code, signatures are applied to the hash of the data
    // instead of the raw data itself
    bytes32 hashed = keccak256(abi.encode(voucher.updatedBalance));

    // The prefix string here is part of a convention used in ethereum for signing
    // and verification of off-chain messages. The trailing 32 refers to the 32 byte
    // length of the attached hash message.
    //
    // There are seemingly extra steps here compared to what was done in the off-chain
    // `reimburseService` and `processVoucher`. Note that those ethers signing and verification
    // functions do the same under the hood.
    //
    // see https://blog.ricmoo.com/verifying-messages-in-solidity-50a94f82b2ca
    bytes memory prefixed = abi.encodePacked("\x19Ethereum Signed Message:\n32", hashed);
    bytes32 prefixedHashed = keccak256(prefixed);

    /*
      Checkpoint 4: Recover earnings

      The service provider would like to cash out their hard earned ether.
    */

    //use ecrecover on prefixedHashed and the supplied signature
    address recoveredSignerAddress = ecrecover(prefixedHashed, voucher.sig.v, voucher.sig.r, voucher.sig.s);

    //require that the recovered signer has a running channel with balances[signer] > v.updatedBalance
    require (balances[recoveredSignerAddress] > voucher.updatedBalance, "The balance of the signer must be greater than the voucher");

    //calculate the payment when reducing balances[signer] to v.updatedBalance
    uint256 payment = balances[recoveredSignerAddress] - voucher.updatedBalance;

    console.log("This is the voucher balance: ");
    console.log(voucher.updatedBalance);

    console.log("Balance of rube before the substraction: ");
    console.log(balances[recoveredSignerAddress]);

    balances[recoveredSignerAddress] -= payment;

    console.log("This is the new balance of the rube address: ");
    console.log(balances[recoveredSignerAddress]);

    //adjust the channel balance, and pay the Guru(Contract owner). Get the owner address with the `owner()` function.

    bool sent = payable(owner()).send(payment);
    require(sent, "There was an error on the withdrawEarnings");

    //emit the Withdrawn event
    emit Withdrawn(recoveredSignerAddress, voucher.updatedBalance);

  }

  /*
    Checkpoint 5a: Challenge the channel

    Create a public challengeChannel() function that:

  */

  function challengeChannel() public {
    //checks that msg.sender has an open channel
    require(balances[msg.sender] > 0, "The sender doesnt have a running channel");

    //updates canCloseAt[msg.sender] to some future time
    canCloseAt[msg.sender] = block.timestamp + 30 seconds;

    //emits a Challenged event
    emit Challenged(msg.sender);
  }

  /*
    Checkpoint 5b: Close the channel

    Create a public defundChannel() function that:
  */
  function defundChannel() public {
    //checks that msg.sender has a closing channel
    require (canCloseAt[msg.sender] > 0, "The sender doesnt have a challenged channel");
    //checks that the current time is later than the closing time
    require (block.timestamp > canCloseAt[msg.sender], "The closing time has not elapsed yet");

    //sends the channel's remaining funds to msg.sender, and sets the balance to 0
    uint256 payment = balances[msg.sender];

    balances[msg.sender] = 0;

    bool sent = payable(msg.sender).send(payment);

    console.log("This is the payment of the defundChannel");
    console.log(payment);
    require(sent, "There was an error on the defundChannel");

    //emits the Closed event
    emit Closed(msg.sender);

  }

  struct Voucher {
    uint256 updatedBalance;
    Signature sig;
  }
  struct Signature {
    bytes32 r;
    bytes32 s;
    uint8 v;
  }
}
