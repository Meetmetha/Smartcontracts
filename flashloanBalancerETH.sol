pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IBalancerVault {
    function flashLoan(
        address recipient,
        address[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;
}

contract flashloanBalancer is Ownable {
    IERC20 TOKEN = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    IBalancerVault vault = IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    
    function InitiateFlashLoan() external onlyOwner {
        //Creating Flashloan data
        address[] memory tokens = new address[](1);
        tokens[0] = address(TOKEN);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 30 * 10**8; //(FlashLoanToken * 10 ** decimalsOfToken) here its 30WBTC
        vault.flashLoan(address(this), tokens, amounts, "");//Initiate the flashloan call
    }
    //Callback from balancer
    function receiveFlashLoan(IERC20[] memory tokens,uint256[] memory amounts,uint256[] memory feeAmounts,bytes memory userData) external {
        //DO your Actions here and at the end just transfer back flashloaned amount 
        TOKEN.transfer(address(vault), 30 * 10**8);
    }

    function recoverEther() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    function recoverTokens(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(owner(), token.balanceOf(address(this)));
    }
    
    fallback() external payable {}
    receive() external payable {}
}
