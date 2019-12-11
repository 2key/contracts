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
	mapping(address => bool) areRewardsWithdrawn;
	mapping(address => uint) amountInfluencerEarned;

	// Dollar to 2key rate in WEI at the moment of adding inventory
	uint public usd2KEYrateWei;

	// Variable to let us know if rewards have been bought with Ether
	bool public boughtRewardsWithEther;

	// Bounty how contractor wants referrers to split per conversion
	uint public bountyPerConversion;

	//Amount for rewards inventory
	uint public rewardsInventoryAmount;


	/**
     * @notice Internal function to check the balance of the specific ERC20 on this contract
     */
	function getTokenBalance()
	internal
	view
	returns (uint)
	{
		address twoKeyEconomy = getNonUpgradableContractAddressFromRegistry("TwoKeyEconomy");
		return IERC20(twoKeyEconomy).balanceOf(address(this));
	}

	function transferERC20(
		address receiver,
		uint amount
	)
	internal
	{
		address twoKeyEconomy = getNonUpgradableContractAddressFromRegistry("TwoKeyEconomy");
		IERC20(twoKeyEconomy).transfer(receiver, amount);
	}


    /**
	 * @notice Function to add fiat inventory for rewards
	 * @dev only contractor can add this inventory
	 */
	function buyReferralBudgetWithEth()
	public
	onlyContractor
	payable
	{
		//It can be called only ONCE per campaign
		require(usd2KEYrateWei == 0);

		boughtRewardsWithEther = true;
		rewardsInventoryAmount = buyTokensFromUpgradableExchange(msg.value, address(this));


		uint rateUsdToEth = ITwoKeyExchangeRateContract(getAddressFromTwoKeySingletonRegistry("TwoKeyExchangeRateContract")).getBaseToTargetRate("USD");
		usd2KEYrateWei = (msg.value).mul(rateUsdToEth).div(rewardsInventoryAmount); //0.1 DOLLAR
	}

	/**
	 * @notice Function which assumes that contractor already called approve function on 2KEY token contract
	 * @param _amount is the amount he called previously approve with
	 */
	function addDirectly2KEYAsInventory(
		uint _amount
	)
	public
	onlyContractor
	{
		require(getTokenBalance() == 0);

		IERC20(twoKeyEconomy).transferFrom(msg.sender, address(this), _amount);

		rewardsInventoryAmount = _amount;

	}


	/**
     * @notice Function to withdraw remaining rewards inventory in the contract
     */
	function withdrawRemainingRewardsInventory() public onlyContractor
	returns (uint)
	{
		require(ITwoKeyCampaignLogicHandler(logicHandler).canContractorWithdrawRemainingRewardsInventory() == true);
		uint campaignRewardsBalance = getTokenBalance();

		uint rewardsNotSpent = campaignRewardsBalance.sub(reservedAmount2keyForRewards);
		if(rewardsNotSpent > 0) {
			IERC20(twoKeyEconomy).transfer(contractor, rewardsNotSpent);
		}
		return rewardsNotSpent;
	}

}
