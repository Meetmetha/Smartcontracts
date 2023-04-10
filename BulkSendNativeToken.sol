pragma solidity ^0.8.0;

contract Wallet {
    address private constant owner = 0xaddress; //Address to set owner

    constructor() payable {}
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Dont do this please");
        _;
    }
    
    function sendEth(address[] calldata wallets) external payable onlyOwner {
        uint256 amountToSend = wallets.length * 0.0001 ether;
        require(msg.value >= amountToSend, "Insufficient ether sent to the function");
        for (uint256 i = 0; i < wallets.length; i++) {
            payable(wallets[i]).transfer(0.0001 ether);
        }
    }

    function sendEthtoOne(address wallets) external payable onlyOwner {
        payable(wallets).transfer(0.0001 ether);
    }
    
    function recoverEther() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
    
    function recoverTokens(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(owner, token.balanceOf(address(this)));
    }
    
    fallback() external payable {}
    receive() external payable {}
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}
