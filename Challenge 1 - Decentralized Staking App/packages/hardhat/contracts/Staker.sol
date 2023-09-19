// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  //SMART CONTRACT VARIABLES
  
  mapping(address => uint256) public balances;

  uint256 public constant threshold = 1 ether;

  uint256 public deadline = block.timestamp + 72 hours;

  bool public openForWithdraw = false;


  //SMART CONTRACT EVENTS
  // ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  event Stake(address indexed investor, uint256 deposit);

  event OpenForWithdraw(uint256 timestamp);

  event StakeSentToExternalContract(address externalContract, uint256 timestamp);

  //SMART CONTRACT MODIFIERS
  modifier notCompleted() {
    require(exampleExternalContract.completed() == false, "The external contract is already completed");
    _;
  }

  modifier deadlineNotOver() {
    require(this.timeLeft()>0, "The deadline is over, you can't stake more funds");
    _;
  }


  //SMART CONTRACT CONSTRUCTOR
  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
      
  }

  //SMART CONTRACT FUNCTIONS

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:

  function stake() public payable notCompleted deadlineNotOver {
    balances[msg.sender] = balances[msg.sender] + msg.value;

    emit Stake(msg.sender, msg.value);
    /*
    //If you stake enough ETH before the deadline, it should call complete()
    if(address(this).balance >= threshold) {
      exampleExternalContract.complete{value: address(this).balance}();

      emit StakeSentToExternalContract(address(exampleExternalContract), block.timestamp);
    }
    */
  }


  // After some `deadline` allow anyone to call an `execute()` function
  // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
  function execute() public notCompleted {
    require (block.timestamp >= deadline, "The deadline has not elapsed yet");

    if(address(this).balance >= threshold) {
      exampleExternalContract.complete{value: address(this).balance}();

      emit StakeSentToExternalContract(address(exampleExternalContract), block.timestamp);

    } else {
      // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
      openForWithdraw = true;

      emit OpenForWithdraw(block.timestamp);
    }
    
  }

  //If you don't stake() enough you can withdraw() your funds after the deadline
  function withdraw() public payable notCompleted {
    require(openForWithdraw == true, "You can't withdraw funds because the Staker is not open for withdraw");
    require(balances[msg.sender] > 0, "You have no balance to withdraw");

    uint256 balanceToRefund = balances[msg.sender]; 
    balances[msg.sender] = 0;

    bool sent = payable(msg.sender).send(balanceToRefund);
    require(sent, "Failure, ether not sent");
  }


  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256) {

      if(block.timestamp >= deadline) {
        return 0;  // Be careful! if block.timestamp >= deadline you want to return 0;
      }
      return deadline - block.timestamp;
  }


  // Add the `receive()` special function that receives eth and calls stake()
   receive() external payable {
    this.stake();
  }
}
