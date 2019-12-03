pragma solidity ^0.4.24;

import "./TwoKeyCampaign.sol";
import "../interfaces/ITwoKeyExchangeRateContract.sol";
import "../interfaces/ITwoKeyCampaignLogicHandler.sol";
import "../interfaces/IERC20.sol";

/**
 * @author Nikola Madjarevic (https://github.com/madjarevicn)
 */
contract TwoKeyBudgetCampaign is TwoKeyCampaign {

	/**
	 * This is the BudgetCampaign contract abstraction which will
	 * be implemented by all budget campaigns in future
	 */

	// Dollar to 2key rate in WEI at the moment of adding inventory
	uint public usd2KEYrateWei;

	// Variable to let us know if rewards have been bought with Ether
	bool public boughtRewardsWithEther;

	/**
     * @notice Internal function to check the balance of the specific ERC20 on this contract
     * @param tokenAddress is the ERC20 contract address
     */
	function getTokenBalance( //TODO probably not required - in these types of campaigns tokens are not being sold
		address tokenAddress
	)
	internal
	view
	returns (uint)
	{
		return IERC20(tokenAddress).balanceOf(address(this));
	}


    /**
	 * @notice Function to add fiat inventory for rewards
	 * @dev only contractor can add this inventory
	 */
	function buyReferralBudgetWithEth()  //TODO where's the function to purchase rewards budget directly by inserting 2KEY?
	public
	onlyContractor
	payable
	{
		//It can be called only ONCE per campaign
		require(usd2KEYrateWei == 0);

		boughtRewardsWithEther = true;
		uint amountOfTwoKeys = buyTokensFromUpgradableExchange(msg.value, address(this));
		uint rateUsdToEth = ITwoKeyExchangeRateContract(getAddressFromTwoKeySingletonRegistry("TwoKeyExchangeRateContract")).getBaseToTargetRate("USD");

		usd2KEYrateWei = (msg.value).mul(rateUsdToEth).div(amountOfTwoKeys); //0.1 DOLLAR
	}


	/**
     * @notice Function to withdraw remaining rewards inventory in the contract
     */
	function withdrawRemainingRewardsInventory() public onlyContractor
	returns (uint)
	{
		require(ITwoKeyCampaignLogicHandler(logicHandler).canContractorWithdrawRemainingRewardsInventory() == true);
		uint campaignRewardsBalance = getTokenBalance(twoKeyEconomy);

		uint rewardsNotSpent = campaignRewardsBalance.sub(reservedAmount2keyForRewards);
		if(rewardsNotSpent > 0) {
			IERC20(twoKeyEconomy).transfer(contractor, rewardsNotSpent);
		}
		return rewardsNotSpent;
	}

}
