pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IUniswapV2Router {
  function getAmountsOut(uint256 amountIn, address[] memory path)
    external
    view
    returns (uint256[] memory amounts);
  
  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);
}

contract tokenSwap is Ownable {
    
    IUniswapV2Router UNISWAP_V2_ROUTER = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //Mainnet Uniswap V2 Router => 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    IERC20 WETH = IERC20(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6); //WETH Address Mainnet=> 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    
    function WETHtoToken(address _Tokento, uint256 _amount) external onlyOwner {
        IERC20 Token = IERC20(_Tokento); //Token address to swap
        WETH.approve(address(UNISWAP_V2_ROUTER), type(uint256).max);
        //this path array will have 3 addresses [tokenIn, WETH, tokenOut] we will do WETH path only
        address[] memory path;
        path = new address[](2);
        path[0] = address(WETH);
        path[1] = address(Token);
        uint256[] memory _amountOutMinsArray = UNISWAP_V2_ROUTER.getAmountsOut(_amount, path);
        uint256 _amountOutMin = _amountOutMinsArray[path.length -1];
        UNISWAP_V2_ROUTER.swapExactTokensForTokens(_amount, _amountOutMin, path, address(this), block.timestamp);
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
