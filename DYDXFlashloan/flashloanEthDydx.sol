pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./DydxFlashloanBase.sol";
import "./ICallee.sol";

contract FlashSwapDYDX is ICallee, DydxFlashloanBase, Ownable {
    //Constants Config
    address public flashUser;
    address constant pooladdress = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e; //DYDX Pool Mainnet => 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e
    struct requestData { //Input data while asking for loan
        address token;
        uint repayAmount;
    }

    /*
    DYDX Flashloan works by calling operate function of pool which is an array requesting 3 Actions
    We will create InitiateFlashloan function which will do following
    1) Withdraw Loan - _getWithdrawAction()
    2) CallBack - _getCallAction()
    3) Payback Loan + Interest - getDepositAction() [Calculate repayment using _getRepaymentAmountInternal]
    */

    //Initiate Flashloan
    function initiateFlashloan(address _token, uint _amount) external {
        ISoloMargin solo = ISoloMargin(pooladdress); //Initialise solo address pool
        uint marketId = _getMarketIdFromTokenAddress(pooladdress, _token); //Its just an ID given to Tokens which can be flashloaned => 0 WETH; 1 SAI, 2 USDC, 3 DAI
        uint repayAmount = _getRepaymentAmountInternal(_amount);//Calculate repayment amount needed post flashloan so we can approve it before hand
        IERC20(_token).approve(pooladdress, repayAmount);

        bytes memory data = abi.encode( //Data sent to call function which we will utilise it later
            requestData({token: _token, repayAmount: repayAmount})
        );

        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3); //Action Arguments array named operations of size 3 as explained above i.e 3 Operations
        operations[0] = _getWithdrawAction(marketId, _amount);
        operations[1] = _getCallAction(data);
        operations[2] = _getDepositAction(marketId, repayAmount);
        Account.Info[] memory accountInfo = new Account.Info[](1); //This is needed by DYDX to know accounts involving in Trnx
        accountInfo[0] = _getAccountInfo();
        solo.operate(accountInfo, operations); //Execute Operations
    }

    function callFunction(
        address sender,
        Account.Info memory account,
        bytes memory data
    ) public override {
        require(msg.sender == pooladdress, "Invalid Caller it needs to be DYDX Pool");
        require(sender == address(this), "Invalid Caller, Self call not allowed");

        requestData memory mcd = abi.decode(data, (requestData)); //Decode call and get back your data you sent in operations
        uint repayAmount = mcd.repayAmount;

        uint balanceRepay = IERC20(mcd.token).balanceOf(address(this));
        require(balanceRepay >= repayAmount, "bal < repayAmount");

        // Custom code - Arbitrage
        flashUser = sender;
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