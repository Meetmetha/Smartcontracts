pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IRouter {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IDPPOracle {
    function flashLoan(
        uint256 baseAmount,
        uint256 quoteAmount,
        address assetTo,
        bytes calldata data
    ) external;
}

interface IDODOCallee {
    function DPPFlashLoanCall(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external;
}

contract FlashloanSwap is Ownable {
    address public TokenToFlashSwap;
    uint256 public amount;

    constructor(address _TokenToFlashSwap,uint256 _amount){
        TokenToFlashSwap = _TokenToFlashSwap;
        amount = _amount;
    }

    IERC20 WBNB = IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c); //Pancake Mainnet
    IRouter Router = IRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E); //Pancake Router Mainnet
    IDPPOracle DPP = IDPPOracle(0xFeAFe253802b77456B4627F8c2306a9CeBb5d681); //Flashloan via Dodo
    
    function FlahloanAndSwap() public onlyOwner(){ //Initiate Flashloan
        DPP.flashLoan(amount, 0, address(this), "0x1");  
    }

    function DPPFlashLoanCall(address, uint256 baseAmount, uint256, bytes calldata) external { //Flashloan call back and repay at end
        IERC20 Token = IERC20(TokenToFlashSwap);
        WBNB.approve(address(Router), type(uint).max);
        Token.approve(address(Router), type(uint).max);
        address[] memory path = new address[](2);
        path[0] = address(WBNB);
        path[1] = address(Token);
        Router.swapExactTokensForTokensSupportingFeeOnTransferTokens( //Swap WBNB to Token
            amount,
            0,
            path, 
            address(this),
            type(uint).max
        );
        address[] memory pathreswap = new address[](2);
        pathreswap[0] = address(Token);
        pathreswap[1] = address(WBNB);
        Router.swapExactTokensForTokensSupportingFeeOnTransferTokens( //Swap Token back to WBNB
            Token.balanceOf(address(this)),
            0,
            pathreswap, 
            address(this),
            type(uint).max
        );
        WBNB.transfer(address(DPP), baseAmount); //Repay Flashloan
    }

    function updateAddressAndAmount(address _TokenToFlashSwap,uint256 _amount) public onlyOwner{ 
        TokenToFlashSwap = _TokenToFlashSwap;
        amount = _amount;
    }

    function getTokenToFlashSwap() public view returns (address) {
        return TokenToFlashSwap;
    }

    function getAmount() public view returns (uint256) {
        return amount;
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
