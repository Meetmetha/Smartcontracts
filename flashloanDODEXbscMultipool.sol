pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
interface DVM {
  function flashLoan(
    uint256 baseAmount,
    uint256 quoteAmount,
    address assetTo,
    bytes calldata data
  ) external;

  function init(
    address maintainer,
    address baseTokenAddress,
    address quoteTokenAddress,
    uint256 lpFeeRate,
    address mtFeeRateModel,
    uint256 i,
    uint256 k,
    bool isOpenTWAP
  ) external;

  function _BASE_TOKEN_() external returns(address);
  function _QUOTE_TOKEN_() external returns(address);
}

contract flashloanDODEX is Ownable {
    IERC20 TOKEN = IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);//Token to flashloan
    address dodo1 = 0x6098A5638d8D7e9Ed2f952d35B2b67c34EC6B476; //Flashloan Pool1
    address dodo2 = 0xFeAFe253802b77456B4627F8c2306a9CeBb5d681; //Flashloan Pool2
    uint256 dodoFlashAmount1;
    uint256 dodoFlashAmount2;
    
    function InitiateFlashLoan() external onlyOwner {
        dodoFlashAmount1 = TOKEN.balanceOf(dodo1);
        DVM(dodo1).flashLoan(dodoFlashAmount1, 0, address(this), new bytes(1));//Initiate Flashloan
    }
    //Callback from balancer
    function DPPFlashLoanCall(address sender, uint256 baseAmount, uint256 quoteAmount, bytes calldata data) external {
        if (msg.sender == dodo1) {
            dodoFlashAmount2 = WBNB.balanceOf(dodo2);
            DVM(dodo2).flashLoan(dodoFlashAmount2, 0, address(this), new bytes(1));//Calling another flashloan on pool2 to get max BNB
            TOKEN.transfer(dodo1, dodoFlashAmount1);//Repay flashloan to pool1
        } else if (msg.sender == dodo2) {
            //Do your profitable transactions here 
            TOKEN.transfer(dodo2, dodoFlashAmount2); //Repay flashloan to pool2
        }
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
