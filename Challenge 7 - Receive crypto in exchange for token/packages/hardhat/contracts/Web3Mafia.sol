// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


interface MaticTokenInterface {
    function transfer(address dst, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function balanceOf(address guy) external view returns (uint);
}

interface UsdcTokenInterface {
    function transfer(address dst, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function balanceOf(address guy) external view returns (uint);
}

contract Web3Mafia is ERC20Pausable, Ownable {

    ////////////////// SMART CONTRACT VARIABLES //////////////////


    //////////MATIC VARIABLES//////////
    
    //Address of MATIC token in the blockchain
    address public maticTokenAddress = 0x388E8F01fE2c2d1Ae8ce8B8A18e1De03F9e0A8F8;

    //Address of MATIC token price feed (Oracle) in the blockchain
    address public maticPriceFeedAddress = 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada;

    //Aggregator that allows to ask for the price of crypto tokens
    AggregatorV3Interface internal dataFeedMatic;

    //Declaration of MATIC token interface
    MaticTokenInterface public maticToken;


    /////////////USDC VARIABLES//////////

    //Address of USDC token in the blockchain
    address public usdcTokenAddress = 0xAD42272cA8cEF831cC442E744eF2ab6a38BE7295;

    //Address of USDC token price feed (Oracle) in the blockchain
    address public usdcPriceFeedAddress = 0x572dDec9087154dC5dfBB1546Bb62713147e0Ab0;

    //Aggregator that allows to ask for the price of crypto tokens
    AggregatorV3Interface internal dataFeedUsdc;

    //Declaration of USDC token interface
    UsdcTokenInterface public usdcToken;



    //Setting the amount of tokens to give in exchange for 1 USD
    uint256 public w3mTokenPrice = 166;

    ////////////////// SMART REQUIRED CONSTRUCTOR //////////////////
    constructor() ERC20("Web3Mafia", "W3M") Ownable()
    {   
        _mint(msg.sender, 2000000000 * 10 ** decimals());

        //Oracle on Mumbai network for MATIC/USD https://mumbai.polygonscan.com/address/0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
        dataFeedMatic = AggregatorV3Interface(maticPriceFeedAddress);

        //Implementation of MATIC token interface
        maticToken = MaticTokenInterface(maticTokenAddress);

        //Oracle on Mumbai network for USDC/USD https://mumbai.polygonscan.com/address/0x572dDec9087154dC5dfBB1546Bb62713147e0Ab0
        dataFeedUsdc = AggregatorV3Interface(usdcPriceFeedAddress);

        //Implementation of USDC token interface
        usdcToken = UsdcTokenInterface(usdcTokenAddress);
    }

    ////////////////// SMART CONTRACT FUNCTIONS //////////////////

    function investFromMatic() public payable returns (bool){

        //Transfer MATIC to this contract. Its automatically done with the payable tag
        //Amount to transfer should greater than zero
        require(msg.value > 0, "Amount of MATIC to invest should be greater than 0");

        //Transfer MATIC to the owner wallet
        bool successSendingMatic = payable(owner()).send(msg.value);
        require (successSendingMatic, "There was an error on sending the MATIC investment to the owner");

        //Get the current Matic price from function
        uint256 currentMaticPrice = getCurrentMaticPrice();

        //Calculate the total investment in USD and divide by 10**8. Because the MATIC price feed comes with 8 decimals
        uint256 totalInvestmentInUsd = (msg.value * currentMaticPrice) / 100000000; 

        //Calcuale the amount of tokens to return given the current token price
        uint256 totalW3MTokenToReturn = totalInvestmentInUsd * w3mTokenPrice;
        
        //Transfer W3M token to the investor wallet
        bool successSendingW3MToken = this.transfer(msg.sender, totalW3MTokenToReturn);
        require (successSendingW3MToken, "There was an error on sending back the W3M Token to the investor");

        return successSendingW3MToken;
    }


    function investFromUsdc(uint256 _amount) public returns (bool) {

        //Amount to transfer should greater than zero
        require(_amount > 0, "Amount of USDC to invest should be greater than 0");

        //Transfer USDC to this contract
        bool successReceivingUsdc  = usdcToken.transferFrom(msg.sender, address(this), _amount);
        require (successReceivingUsdc, "There was an error on receiving the USDC investment");

        //Transfer USDC to the owner wallet
        bool successSendingUsdc = usdcToken.transfer(payable(owner()), _amount);
        require (successSendingUsdc, "There was an error on sending the USDC investment to the owner");

        //Get the current USDC price from function
        uint256 currentUsdcPrice = getCurrentUsdcPrice();

        //Calculate the total investment in USD and divide by 10**8. Because the USDC price feed comes with 8 decimals
        uint256 totalInvestmentInUsd = (_amount * currentUsdcPrice) / 100000000; 

        //Calcuale the amount of tokens to return given the current token price
        uint256 totalW3MTokenToReturn = totalInvestmentInUsd * w3mTokenPrice;
        
        //Transfer W3M token to the investor wallet
        bool successSendingW3MToken = this.transfer(msg.sender, totalW3MTokenToReturn);
        require (successSendingW3MToken, "There was an error on sending back the W3M Token to the investor");

        return successSendingW3MToken;
    }


    function getCurrentMaticPrice () public view returns (uint256) {
        (
            /* uint80 roundID */,
            int256 answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeedMatic.latestRoundData();
        
        return uint256(answer);
    }

    function getCurrentUsdcPrice () public view returns (uint256) {
        (
            /* uint80 roundID */,
            int256 answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeedUsdc.latestRoundData();
        
        return uint256(answer);
    }

    ////////////////// SMART REQUIRED FUNCTIONS //////////////////

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        require(newOwner != address(this), "Ownable: new owner is the same contract address");
        _transferOwnership(newOwner);
    }

    receive() external payable {
    }

}
