pragma solidity ^0.4.18;

import "./KyberNetworkProxy.sol";

contract ERC20Exchange {
    ERC20 constant internal ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
    KyberNetworkProxy public kyberNetworkProxyContract;

    event SwapERC20ToERC20(address indexed sender, ERC20 srcToken, ERC20 destToken, uint amount);
    event SwapETHToToken(address indexed sender, ERC20 destToken, uint amount);
    event SwapTokenToETH(address indexed sender, ERC20 srcToken, uint amount);

    function setInitialParams(
        KyberNetworkProxy _kyberNetworkProxyContract
    )
    public
    {
        kyberNetworkProxyContract = _kyberNetworkProxyContract;
    }


    function executeETHErc20Swap(ERC20 token, address destAddress) public payable {
        uint minConversionRate;

        // Get the minimum conversion rate
        (minConversionRate,) = kyberNetworkProxyContract.getExpectedRate(ETH_TOKEN_ADDRESS, token, msg.value);

        // Swap the ETH to ERC20 token
        uint destAmount = kyberNetworkProxyContract.swapEtherToToken.value(msg.value)(token, minConversionRate);

        // Send the swapped tokens to the destination address
        require(token.transfer(destAddress, destAmount));

        // Log the event
        SwapETHToToken(msg.sender, token, destAmount);
    }


    function executeErc20ETHSwap(ERC20 token, uint tokenQty, address destAddress) public {
        uint minConversionRate;

        // Check that the token transferFrom has succeeded
        require(token.transferFrom(msg.sender, address(this), tokenQty));

        // Mitigate ERC20 Approve front-running attack, by initially setting
        // allowance to 0
        require(token.approve(address(kyberNetworkProxyContract), 0));

        // Set the spender's token allowance to tokenQty
        require(token.approve(address(kyberNetworkProxyContract), tokenQty));

        // Get the minimum conversion rate
        (minConversionRate,) = kyberNetworkProxyContract.getExpectedRate(token, ETH_TOKEN_ADDRESS, tokenQty);

        // Swap the ERC20 token to ETH
        uint destAmount = kyberNetworkProxyContract.swapTokenToEther(token, tokenQty, minConversionRate);

        // Send the swapped ETH to the destination address
        destAddress.transfer(destAmount);

        // Log the event
        SwapTokenToETH(msg.sender, token, destAmount);
    }


    function executeErc20Erc20Swap(ERC20 srcToken, uint srcQty, ERC20 destToken, address destAddress) public {
        uint minConversionRate;

        // Check that the token transferFrom has succeeded
        require(srcToken.transferFrom(msg.sender, address(this), srcQty));

        // Mitigate ERC20 Approve front-running attack, by initially setting
        // allowance to 0
        require(srcToken.approve(address(kyberNetworkProxyContract), 0));

        // Set the spender's token allowance to tokenQty
        require(srcToken.approve(address(kyberNetworkProxyContract), srcQty));

        // Get the minimum conversion rate
        (minConversionRate,) = kyberNetworkProxyContract.getExpectedRate(srcToken, ETH_TOKEN_ADDRESS, srcQty);

        // Swap the ERC20 token to ETH
        uint destAmount = kyberNetworkProxyContract.swapTokenToToken(srcToken, srcQty, destToken, minConversionRate);

        // Send the swapped tokens to the destination address
        require(destToken.transfer(destAddress, destAmount));

        // Log the event
        SwapERC20ToERC20(msg.sender, srcToken, destToken, destAmount);
    }
}
