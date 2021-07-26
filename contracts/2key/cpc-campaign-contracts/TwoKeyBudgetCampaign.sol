pragma solidity ^0.4.24;

import "../interfaces/ITwoKeyExchangeRateContract.sol";
import "../interfaces/ITwoKeyCampaignLogicHandler.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/ITwoKeyFeeManager.sol";

import "../campaign-mutual-contracts/TwoKeyCampaign.sol";
//import "../libraries/MerkleProof.sol";

/**
 * @author Nikola Madjarevic (https://github.com/madjarevicn)
 */
contract TwoKeyBudgetCampaign is TwoKeyCampaign {

	/**
	 * IN ALL BUDGET TYPE CAMPAIGNS MAPPING: referrerPlasma2Balances2KEY(address => uint) is contained from following:
	 *  address : referrer PUBLIC address
	 *  uint : value how much balance he has
	 */

	/**
	 * This is the BudgetCampaign contract abstraction which will
	 * be implemented by all budget campaigns in future
	 */

	struct RebalancedRates {
		uint priceAtBeginning;
		uint priceAtRebalancingTime;
		uint ratio;
	}




	bool public isContractLocked;							// If the contract is locked
	address public mirrorCampaignOnPlasma;					// Address of campaign deployed to plasma network
	bool public isValidated;								// Flag to determine if campaign is validated

	bool public isInventoryAdded;							// Selector if inventory is added
	bool public boughtRewardsWithEther;						// Variable to let us know if rewards have been bought with Ether
	bool public contractorWithdrawnLeftOverTokens;			// Variable which will let us know if contractor has withdrawn leftover

	uint public usd2KEYrateWei;								// Dollar to 2key rate in WEI at the moment of adding inventory
	uint public bountyPerConversion;						// Bounty how contractor wants referrers to split per conversion
	uint public initialInventoryAmount;						// Amount for rewards inventory added firstly
	uint public moderatorTotalEarnings;						// Amount representing how much moderator has earned

	uint public leftOverTokensForContractor;
	uint public totalRewardsDistributed;

	mapping(address => uint256) referrerPlasma2TotalEarnings2key;	// Total earnings per referrer

	RebalancedRates rebalancedRatesStruct; // Instance of rebalanced rates structure


	/**
     * @notice 			Function to validate that contracts plasma and public are well mirrored
     */
	function validateContractFromMaintainer()
	public
	onlyMaintainer
	{
		isValidated = true;
	}


	/**
     * @notice 			Internal function to check the balance of the specific ERC20 on this contract
     */
	function getTokenBalance()
	internal
	view
	returns (uint)
	{
		return IERC20(twoKeyEconomy).balanceOf(address(this));
	}

	/**
	 * @notice 			Function to transfer 2KEY tokens
	 *
	 * @param			receiver is the address of tokens receiver
	 * @param			amount is the amount of tokens to be transfered
	 */
	function transfer2KEY(
		address receiver,
		uint amount
	)
	internal
	{
		IERC20(twoKeyEconomy).transfer(receiver, amount);
	}

	/**
	 * @notice 			Function which assumes that contractor already called approve function on 2KEY token contract
	 */
	function addDirectly2KEYAsInventory()
	public
	onlyContractor
	{
		require(isInventoryAdded == false);

		initialInventoryAmount = getTokenBalance();

		isInventoryAdded = true;
	}

	/**
     * @notice 			Function to add fiat inventory for rewards
     * @dev				only contractor can add this inventory
     */
	function buyReferralBudgetWithEth()
	public
	onlyContractor
	payable
	{
		//It can be called only ONCE per campaign
		require(isInventoryAdded == false);

		boughtRewardsWithEther = true;
		(initialInventoryAmount,usd2KEYrateWei) = buyTokensFromUpgradableExchange(msg.value, address(this));

		rebalancedRatesStruct.priceAtBeginning = usd2KEYrateWei;

		isInventoryAdded = true;
	}


	/**
	 * @notice			Function to rebalance the rates in the contract depending of
	 *					either 2KEY price went up or down after we bought tokens
	 */
    function rebalanceRates(
		uint amountToRebalance
	)
    internal
    {
        address twoKeyUpgradableExchange = getAddressFromTwoKeySingletonRegistry("TwoKeyUpgradableExchange");

        // Take the current usd to 2KEY rate
        uint usd2KEYRateWeiNow = IUpgradableExchange(twoKeyUpgradableExchange).sellRate2key();

        //Now check if rate went up
        if(usd2KEYRateWeiNow > usd2KEYrateWei) {
            uint tokensToBeGivenBackToExchange = reduceBalance(usd2KEYRateWeiNow, amountToRebalance);
			// Approve upgradable exchange to take leftover back
            IERC20(twoKeyEconomy).approve(twoKeyUpgradableExchange, tokensToBeGivenBackToExchange);
			// Call the function to release all DAI for this contract to reserve and to take approved amount of 2key back to liquidity pool
			IUpgradableExchange(twoKeyUpgradableExchange).returnLeftoverAfterRebalancing(tokensToBeGivenBackToExchange);
        }
        // Check if rate went down
        else if(usd2KEYRateWeiNow < usd2KEYrateWei) {
            uint tokensToBeTakenFromExchange = increaseBalance(usd2KEYRateWeiNow, amountToRebalance);
            // Get more tokens we need
            IUpgradableExchange(twoKeyUpgradableExchange).getMore2KeyTokensForRebalancing(tokensToBeTakenFromExchange);
        } else {
			rebalancedRatesStruct = RebalancedRates(0,0,10**18);
		}
    }


    /**
     * @notice 			Function which will reduce influencers balance in case 2key rate went up
     * @param 			newRate is the new rate of 2key token
     */
    function reduceBalance(
        uint newRate,
		uint amountToRebalance
    )
    internal
    returns (uint)
    {
		uint currentBalance = amountToRebalance;
		// Compute what's going to be the new balance for moderator and influencers together
		uint newBalance = currentBalance.mul(usd2KEYrateWei).div(newRate);
		// Compute how much will stay as leftover and will be returned to exchange
		uint amountToReturnToExchange = currentBalance.sub(newBalance);
		// Compute the ratio in wei
		uint ratioInWEI = usd2KEYrateWei.mul(10**18).div(newRate);
		// Create struct which will store what was old and new rate after rebalancing + it's ratio
		rebalancedRatesStruct = RebalancedRates(
			usd2KEYrateWei,
			newRate,
			ratioInWEI
		);

		twoKeyEventSource.emitRebalancedRatesEvent(
			usd2KEYrateWei,
			newRate,
			ratioInWEI,
			amountToReturnToExchange,
			"RETURN_TOKENS_TO_EXCHANGE"
		);

		// Return the amount we're returning to exchange
        return amountToReturnToExchange;
    }

    /**
     * @notice 			Function which will increase influencers balance in case 2key rate went down
     * @param 			newRate is the new rate of 2key token
     */
    function increaseBalance(
        uint newRate,
		uint amountToRebalance
    )
    internal
    returns (uint)
    {
		uint currentBalance = amountToRebalance;
		// Compute what's going to be the new balance for moderator and influencers together
		uint newBalance = currentBalance.mul(usd2KEYrateWei).div(newRate);
		// Compute how much will stay as leftover and will be returned to exchange
		uint amountToGetFromExchange = newBalance.sub(currentBalance);
		// Compute the ratio in wei
		uint ratioInWEI = usd2KEYrateWei.mul(10**18).div(newRate);

		// Create struct which will store what was old and new rate after rebalancing + it's ratio
		rebalancedRatesStruct = RebalancedRates(
			usd2KEYrateWei,
			newRate,
			ratioInWEI
		);

		// Emit rebalanced event
		twoKeyEventSource.emitRebalancedRatesEvent(
			usd2KEYrateWei,
			newRate,
			ratioInWEI,
			amountToGetFromExchange,
			"GET_TOKENS_FROM_EXCHANGE"
		);

		return amountToGetFromExchange;
	}


	/**
     * @notice 			Function to withdraw remaining rewards inventory in the contract
     *
     * 					Contractor can call it only once
     */
	function withdrawRemainingRewardsInventory()
    public
    onlyContractor
	{
		require(isContractLocked == true, 'Campaign not ended yet - contract is still not locked.');
		require(contractorWithdrawnLeftOverTokens == false);

		IERC20(twoKeyEconomy).transfer(contractor, leftOverTokensForContractor);
		contractorWithdrawnLeftOverTokens = true;
	}

//	/**
//	 * @notice 			Function to validate the Merkle Proof
//	 */
//	function checkMerkleProof(
//		address influencer,
//		bytes32[] proof,
//		uint amount
//	)
//	public
//	view
//	returns (bool)
//	{
//		if(merkleRoot == 0) // merkle root was not yet set by contractor
//			return false;
//		return MerkleProof.verifyProof(proof,merkleRoot,keccak256(abi.encodePacked(influencer,amount)));
//	}


	/**
     * @notice 			set a merkle root of the amount each (active) influencer received.
     *         			(active influencer is an influencer that received a bounty)
     *         			the idea is that the contractor calls computeMerkleRoot on plasma and then set the value manually
     * 					And reserve tokens for rewards for influencers
     */
	function lockContractReserveTokensAndRebalanceRates(
		uint totalAmountForRewards
	)
	public
	onlyMaintainer
	{
		// Check that MerkleRoot is not set already
		require(isContractLocked == false);
		// Set MerkleRoot
		isContractLocked = true;
		// Amount of tokens on contract
		uint amountOfTokensOnContract = getTokenBalance();
		// Require that on contract is persisted more or equal then necessary for rewards
		require(totalAmountForRewards <= amountOfTokensOnContract);
		// Rebalance rates, it's also going to affect contract tokens balance + reserved amount for rewards
		if(usd2KEYrateWei> 0) {
			rebalanceRates(amountOfTokensOnContract);
		} else {
			// Since we're using it later on, ratio is 1 in case the budget was directly added
			rebalancedRatesStruct = RebalancedRates(0,0,10**18);
		}
		// Get how many tokens are on the contract after rebalancing
		uint amountOfTokensOnContractAfterRebalancing = getTokenBalance();

		// The reserved amount for moderator and influencers
		reservedAmount2keyForRewards = totalAmountForRewards.mul(rebalancedRatesStruct.ratio).div(10**18);
		// The leftover goes to contractor
		leftOverTokensForContractor = amountOfTokensOnContractAfterRebalancing.sub(reservedAmount2keyForRewards);
	}


	/**
	 * @notice			Function to push and distribute rewards between influencers
	 *
	 * @param 			influencers is the array of addresses (public) of influencers
	 * @param			balances is the array of balances for the influencers
	 */
	function pushAndDistributeRewardsBetweenInfluencers(
		address [] influencers,
		uint [] balances
	)
	public
	onlyMaintainer
	{
		// Get the ratio of rebalancing
		//uint rebalancingRatio = rebalancedRatesStruct.ratio;
		// Counter for influencers
		uint i;
		// Create counter for how much is total distributed in this iteration
		uint totalDistributed = 0;

		for(i = 0; i < influencers.length; i++) {
			// Compute how much will be influencer reward with rebalancing ratio
			//uint rebalancedInfluencerBalance = balances[i].mul(rebalancingRatio).div(10**18);  //maintainer already serves rebalanced balances from plasma
            uint rebalancedInfluencerBalance = balances[i];
			// Update total earnings for influencer
			referrerPlasma2TotalEarnings2key[influencers[i]] = referrerPlasma2TotalEarnings2key[influencers[i]].add(rebalancedInfluencerBalance);
			// Transfer tokens to influencer
			IERC20(twoKeyEconomy).transfer(influencers[i], rebalancedInfluencerBalance);
			// Add this amount to total distributed in this iteration
			totalDistributed = totalDistributed.add(rebalancedInfluencerBalance);
		}

		// Update global how much was total distributed in this iteration
		totalRewardsDistributed = totalRewardsDistributed.add(totalDistributed);
		// Require that total rewards we distributed are less or equal than reserved amount 2KEY for rewards
		require(totalRewardsDistributed <= reservedAmount2keyForRewards);
	}

	/**
	 * @notice			Function to distribute rewards for moderator
	 * @param			totalEarnings is the amount for moderator before rebalancing
	 */
	function setAndDistributeModeratorEarnings(
		uint totalEarnings
	)
	public
	onlyMaintainer
	{
		require(moderatorTotalEarnings == 0);
		// Since we did rebalancing we need to change moderator total earnings
		//no need for the ratio rebalance, as this comes from plasma after rebalancing
		//moderatorTotalEarnings = totalEarnings.mul(rebalancedRatesStruct.ratio).div(10**18);
		moderatorTotalEarnings = totalEarnings;

		// Get TwoKeyAdmin address
		address twoKeyAdmin = getAddressFromTwoKeySingletonRegistry("TwoKeyAdmin");
		//Send 2key tokens to moderator
		transfer2KEY(twoKeyAdmin, moderatorTotalEarnings);
		// Update moderator on received tokens so it can proceed distribution to TwoKeyDeepFreezeTokenPool
		ITwoKeyAdmin(twoKeyAdmin).updateReceivedTokensAsModerator(moderatorTotalEarnings);
		// reduce reserved amount of tokens
		totalRewardsDistributed = totalRewardsDistributed.add(moderatorTotalEarnings);

	}



	/**
	 * @notice			Function to get plasma address of a user
	 *
	 * @param			_address is the address for which we want to take plasma address
	 */
	function getPlasmaOf(address _address)
	internal
	view
	returns (address)
	{
		return twoKeyEventSource.plasmaOf(_address);
	}

	/**
	 * @notice			Function to get referrer total rewards and his current balance
	 *
	 * @param			_referrerPlasma is the plasma address of referrer (influencer)
	 */
	function getReferrerTotalRewardsAndCurrentBalance(
		address _referrerPlasma
	)
	public
	view
	returns (uint,uint)
	{
		return (referrerPlasma2TotalEarnings2key[_referrerPlasma], referrerPlasma2Balances2key[_referrerPlasma]);
	}


	/**
	 * @notice			Function to get the amount of bounty reserved for rewards
	 */
	function getReservedAmountForRewards()
	public
	view
	returns (uint)
	{
		return reservedAmount2keyForRewards;
	}

	/**
	 * @notice			Function to get current available inventory on the contract
 	 */
    function getAvailableInventory()
    public
    view
    returns (uint)
    {
        uint currentERC20Balance = getTokenBalance();
        return currentERC20Balance.sub(reservedAmount2keyForRewards);
    }

	function getInventoryStatus()
	public
	view
	returns (uint,uint,uint,uint)
	{
		return (
			totalRewardsDistributed, // how much is currently distributed
			reservedAmount2keyForRewards, // how much was total reserved for influencers and moderator
			leftOverTokensForContractor, // how much contractor got back
			getTokenBalance()
		);
	}

	/**
	 * @notice			Function to get and return the status for rebalancing
	 */
	function getRebalancingStatus()
	public
	view
	returns (uint,uint,uint)
	{
		return (
			rebalancedRatesStruct.priceAtBeginning,
			rebalancedRatesStruct.priceAtRebalancingTime,
			rebalancedRatesStruct.ratio
		);
	}

}
