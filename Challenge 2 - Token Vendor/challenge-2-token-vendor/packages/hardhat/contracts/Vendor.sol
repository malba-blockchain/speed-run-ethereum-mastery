pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable {
  
  event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);

  event SellTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);

  uint256 public constant tokensPerEth = 100;

  YourToken public yourToken;

  constructor(address tokenAddress) {
    yourToken = YourToken(tokenAddress);
  }

  // ToDo: create a payable buyTokens() function:

  function buyTokens() public payable{
    uint256 amountOfTokens = msg.value * tokensPerEth;

    yourToken.transfer(msg.sender, amountOfTokens);
    
    emit BuyTokens(msg.sender, msg.value, amountOfTokens);
  }

  // ToDo: create a withdraw() function that lets the owner withdraw ETH
  //HAVE IN MIND. IN ORDER TO KEEP LIQUIDITY IN THE VENDOR WE MAY DISBLE OR REDUCE THE WITHDRAW FUNCTION

  function withdraw() public onlyOwner {
    
    /*Usually you would input an amount to withdraw. 
    Just to pass the test cases I will assume that
    the owner wants to withdraw everything

    address payable ownerAddress = payable (this.owner());
    bool sent =  ownerAddress.send(_amount);
    */

    address payable ownerAddress = payable (this.owner());
    bool sent =  ownerAddress.send(address(this).balance);

    require(sent, "Error in withdraw of ETH by the owner");

  }

  // ToDo: create a sellTokens(uint256 _amount) function:

  function sellTokens(uint256 _amount) public {

    bool sentTokens = yourToken.transferFrom(msg.sender, address(this), _amount);

    require(sentTokens, "Error in transfering the tokens from the seller to the vendor smart contract");
    

    //Send ETH in exchage of the recieved tokens
    address payable sellerAddress = payable (msg.sender);

    bool sentETH =  sellerAddress.send(_amount/tokensPerEth);

    require(sentETH, "Error in transfering the ETH from the vendor smart contract to the seller");

    emit SellTokens(msg.sender,_amount/tokensPerEth, _amount);
  }

}
