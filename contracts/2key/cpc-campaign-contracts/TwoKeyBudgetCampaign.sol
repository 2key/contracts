pragma solidity ^0.4.24;

import "../interfaces/ITwoKeyExchangeRateContract.sol";
import "../interfaces/ITwoKeyCampaignLogicHandler.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/ITwoKeyFeeManager.sol";

import "../campaign-mutual-contracts/TwoKeyCampaign.sol";
import "../libraries/MerkleProof.sol";

/**
 * @author Nikola Madjarevic (https://github.com/madjarevicn)
 */
contract TwoKeyBudgetCampaign is TwoKeyCampaign {

	/**
	 * This is the BudgetCampaign contract abstraction which will
	 * be implemented by all budget campaigns in future
	 */

	uint [] bountiesAdded;
	bytes32 public merkleRoot;						// Merkle root
	address public mirrorCampaignOnPlasma;			// Address of campaign deployed to plasma network
	bool public isValidated;						// Flag to determine if campaign is validated
	address[] activeInfluencers;						// Active influencer means that he has at least on participation in successful conversion

	mapping(address => bool) isActiveInfluencer;		// Mapping active influencers
	mapping(address => uint) activeInfluencer2idx;	// His index position in the array

	bool public isInventoryAdded;					// Selector if inventory is added
	bool public boughtRewardsWithEther;				// Variable to let us know if rewards have been bought with Ether
	uint public usd2KEYrateWei;						// Dollar to 2key rate in WEI at the moment of adding inventory
	uint public bountyPerConversion;				// Bounty how contractor wants referrers to split per conversion
	uint public initialInventoryAmount;				// Amount for rewards inventory added firstly
	uint public moderatorTotalEarnings;				// Amount representing how much moderator has earned
	uint public moderatorEarningsBalance;			// Amount representing how much moderator has now

	uint public leftOverForContractor;
	bool public contractorWithdrawnLeftover;

	mapping(address => uint256) referrerPlasma2TotalEarnings2key;	// Total earnings per referrer

	struct RebalancedRates {
		uint priceBeforeRebalancing;
		uint priceAfterRebalancing;
		uint ratio;
	}

	RebalancedRates rebalancedRatesStruct;

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

		//TODO: Add funnel for adding inventory multiple times
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

		isInventoryAdded = true;
	}


	/**
	 * @notice			Function to rebalance the rates in the contract depending of
	 *					either 2KEY price went up or down after we bought tokens
	 */
    function rebalanceRates()
    public
    onlyMaintainer
    {
        address twoKeyUpgradableExchange = getAddressFromTwoKeySingletonRegistry("TwoKeyUpgradableExchange");
        // Function which will be used to rebalance rates
        uint usd2KEYRateWeiNow = IUpgradableExchange(twoKeyUpgradableExchange).sellRate2key();

		if(usd2KEYRateWeiNow > usd2KEYrateWei) {
			uint tokensToBeGivenBackToExchange = reduceBalance(usd2KEYRateWeiNow);
			// Approve upgradable exchange to take leftover back
			IERC20(twoKeyEconomy).approve(twoKeyUpgradableExchange, tokensToBeGivenBackToExchange);
			// Call the function to release all DAI for this contract to reserve and to take approved amount of 2key back to liquidity pool
			IUpgradableExchange(twoKeyUpgradableExchange).returnLeftoverAfterRebalancing(tokensToBeGivenBackToExchange);
		}
		// Check if rate went down
		else if(usd2KEYRateWeiNow < usd2KEYrateWei) {
			uint tokensToBeTakenFromExchange = increaseBalance(usd2KEYRateWeiNow);
			// Get more tokens we need
			IUpgradableExchange(twoKeyUpgradableExchange).getMore2KeyTokensForRebalancing(tokensToBeTakenFromExchange);
		} else {
			rebalancedRatesStruct = RebalancedRates(0,0,10**18);
			uint tokenBalance = getTokenBalance();
			leftOverForContractor = tokenBalance.sub(reservedAmount2keyForRewards);
		}
    }



	function reduceBalance(
		uint newRate
	)
	internal
	returns (uint)
	{
		uint currentBalance = getTokenBalance();
		// Compute the ratio in wei
		uint ratioInWEI = usd2KEYrateWei.mul(10**18).div(newRate);
		// Compute what's going to be the new balance for moderator and influencers together
		uint newContractBalance = currentBalance.mul(ratioInWEI).div(10**18);
		// Compute how much will stay as leftover and will be returned to exchange
		uint amountToReturnToExchange = currentBalance.sub(newContractBalance);

		// Create struct which will store what was old and new rate after rebalancing + it's ratio
		rebalancedRatesStruct = RebalancedRates(
			usd2KEYrateWei,
			newRate,
			ratioInWEI
		);

		uint totalInfluencersRewards = 0;

		for(uint i=0; i<activeInfluencers.length; i++) {
			//Taking current influencer balance in 2key
			uint balance = referrerPlasma2Balances2key[activeInfluencers[i]];

			// Computing the new balance for the influencer
			uint newBalance = balance.mul(ratioInWEI).div(10**18);

			// Assigning new balance to the influencer
			referrerPlasma2Balances2key[activeInfluencers[i]] = newBalance;

			// Assign new total earned
			referrerPlasma2TotalEarnings2key[activeInfluencers[i]] = newBalance;

			// Amount to return
			totalInfluencersRewards = totalInfluencersRewards.add(newBalance);
		}

		// Rebalancing for the moderator
		uint newModeratorBalance = moderatorEarningsBalance.mul(ratioInWEI).div(10**18);

		// Updating state vars
		moderatorEarningsBalance = newModeratorBalance;
		moderatorTotalEarnings = newModeratorBalance;

		reservedAmount2keyForRewards = reservedAmount2keyForRewards.mul(ratioInWEI).div(10**18);

		leftOverForContractor = currentBalance.sub(amountToReturnToExchange.add(reservedAmount2keyForRewards));

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
        uint newRate
    )
    internal
    returns (uint)
    {

		uint currentBalance = getTokenBalance();
		// Compute the ratio in wei
		uint ratioInWEI = usd2KEYrateWei.mul(10**18).div(newRate);
		// Compute what's going to be the new balance for moderator and influencers together
		uint newContractBalance = currentBalance.mul(ratioInWEI).div(10**18);
		// Compute how much will stay as leftover and will be returned to exchange
		uint amountToGetFromExchange = newContractBalance.sub(currentBalance);

		// Create struct which will store what was old and new rate after rebalancing + it's ratio
		rebalancedRatesStruct = RebalancedRates(
			usd2KEYrateWei,
			newRate,
			ratioInWEI
		);

		uint totalInfluencersRewards = 0;

		for(uint i=0; i<activeInfluencers.length; i++) {
			//Taking current influencer balance in 2key
			uint balance = referrerPlasma2Balances2key[activeInfluencers[i]];

			// Computing the new balance for the influencer
			uint newBalance = balance.mul(ratioInWEI).div(10**18);

			// Assigning new balance to the influencer
			referrerPlasma2Balances2key[activeInfluencers[i]] = newBalance;

			// Assign new total earned
			referrerPlasma2TotalEarnings2key[activeInfluencers[i]] = newBalance;

			// Amount to return
			totalInfluencersRewards = totalInfluencersRewards.add(newBalance);
		}

		// Rebalancing for the moderator
		uint newModeratorBalance = moderatorEarningsBalance.mul(ratioInWEI).div(10**18);

		// Updating state vars
		moderatorEarningsBalance = newModeratorBalance;
		moderatorTotalEarnings = newModeratorBalance;

		reservedAmount2keyForRewards = reservedAmount2keyForRewards.mul(ratioInWEI).div(10**18);

		leftOverForContractor = currentBalance.add(amountToGetFromExchange).sub(reservedAmount2keyForRewards);

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
     * @notice 			Function to distribute rewards between all the influencers
     * 					which have earned the reward once campaign is done
     * @param 			influencers is the array of influencers
     */
	function distributeRewardsBetweenInfluencers(
		address [] influencers
	)
	public
	onlyMaintainer
	{
		address twoKeyFeeManager = getAddressFromTwoKeySingletonRegistry("TwoKeyFeeManager");
		address twoKeyAdmin = getAddressFromTwoKeySingletonRegistry("TwoKeyAdmin");
		for(uint i=0; i<influencers.length; i++) {
			// Get the influencer balance
			uint balance = referrerPlasma2Balances2key[influencers[i]];
			// If there's some balance then proceed
			if(balance > 0) {
				// Set balance to be 0
				referrerPlasma2Balances2key[influencers[i]] = 0;
				// Reduce reserved amount for rewards
				reservedAmount2keyForRewards = reservedAmount2keyForRewards.sub(balance);
				// Approve twoKeyFeeManager to take 2key tokens in amount of balance from this contract
				IERC20(twoKeyEconomy).approve(twoKeyFeeManager, balance);
				// Pay debt, Fee manager will keep the debt and forward leftover to the influencer
				ITwoKeyFeeManager(twoKeyFeeManager).payDebtWith2KeyV2(
					twoKeyEventSource.ethereumOf(influencers[i]),
					influencers[i],
					balance,
					twoKeyEconomy,
					twoKeyAdmin
				);
			}
		}
	}

	/**
     * @notice 			Function to withdraw remaining rewards inventory in the contract
     */
	function withdrawRemainingRewardsInventory()
    public
    onlyContractor
	{
		require(merkleRoot != 0, 'Campaign not ended yet - merkle root is not set.');
		if(usd2KEYrateWei == 0) {
			uint campaignRewardsBalance = getTokenBalance();
			uint rewardsNotSpent = campaignRewardsBalance.sub(reservedAmount2keyForRewards);
			if(rewardsNotSpent > 0) {
				IERC20(twoKeyEconomy).transfer(contractor, rewardsNotSpent);
			}
		}
		else if(contractorWithdrawnLeftover == false) {
			contractorWithdrawnLeftover = true;
			IERC20(twoKeyEconomy).transfer(contractor, leftOverForContractor);
		}
	}

	/**
	 * @notice 			Function to validate the Merkle Proof
	 */
	function checkMerkleProof(
		address influencer,
		bytes32[] proof,
		uint amount
	)
	public
	view
	returns (bool)
	{
		if(merkleRoot == 0) // merkle root was not yet set by contractor
			return false;
		return MerkleProof.verifyProof(proof,merkleRoot,keccak256(abi.encodePacked(influencer,amount)));
	}

	/**
     * @notice 			set a merkle root of the amount each (active) influencer received.
     *         			(active influencer is an influencer that received a bounty)
     *         			the idea is that the contractor calls computeMerkleRoot on plasma and then set the value manually
     */
	function setMerkleRoot(
		bytes32 _merkleRoot
	)
	public
	onlyMaintainer
	{
		require(merkleRoot == 0);
		merkleRoot = _merkleRoot;
	}


	/**
     * @notice 			Allow maintainers to push balances table
     *
     * @param			influencers is the array of influencers
     * @param			balances is the array of their balances
     */
	function pushBalancesForInfluencers(
		address [] influencers,
		uint [] balances
	)
	public
	onlyMaintainer
	{
		uint i;
		for(i = 0; i < influencers.length; i++) {
			if(isActiveInfluencer[influencers[i]]  == false) {
				activeInfluencers.push(influencers[i]);
				isActiveInfluencer[influencers[i]] = true;
			}
			referrerPlasma2Balances2key[influencers[i]] = referrerPlasma2Balances2key[influencers[i]].add(balances[i]);
			// Update balance
			reservedAmount2keyForRewards = reservedAmount2keyForRewards.add(balances[i]);
			// Update total earned
			referrerPlasma2TotalEarnings2key[influencers[i]] = referrerPlasma2TotalEarnings2key[influencers[i]].add(balances[i]);
		}
		require(reservedAmount2keyForRewards <= getTokenBalance());
	}

	/**
	 * @notice 			Function to set moderator earnings for the campaign
	 * @param 			totalEarnings is the total amount of 2KEY tokens moderator earned
	 * 					This function can be called only once.
	 */
	function setModeratorEarnings(
		uint totalEarnings
	)
	public
	onlyMaintainer
	{
		require(moderatorTotalEarnings == 0);
		moderatorTotalEarnings = totalEarnings;
		moderatorEarningsBalance = totalEarnings;

        reservedAmount2keyForRewards = reservedAmount2keyForRewards.add(totalEarnings);
	}

	/**
	 * @notice 			Function where maintainer can push earnings of moderator for the campaign
	 */
	function distributeModeratorEarnings()
	public
	onlyMaintainer
	{
		address twoKeyAdmin = getAddressFromTwoKeySingletonRegistry("TwoKeyAdmin");
		//Send 2key tokens to moderator
		transfer2KEY(twoKeyAdmin, moderatorEarningsBalance);
		// Update moderator on received tokens so it can proceed distribution to TwoKeyDeepFreezeTokenPool
		ITwoKeyAdmin(twoKeyAdmin).updateReceivedTokensAsModerator(moderatorEarningsBalance);
        // Update reserved amount of tokens
        reservedAmount2keyForRewards = reservedAmount2keyForRewards.sub(moderatorEarningsBalance);
        // Set moderator balance to 0
		moderatorEarningsBalance = 0;
	}


	/**
	 * @notice 			Function to get array of influencers and their rewards
	 *
	 * @param			start is the starting index of influencers array
	 * @param			end is the ending index of influencers array
 	 */
	function getInfluencersWithPendingRewards(
		uint start,
		uint end
	)
	public
	view
	returns (address[], uint[])
	{
		uint[] memory balances = new uint[](end-start);
		address[] memory influencers = new address[](end-start);

		uint index = 0;
		uint indexArr = 0;
		for(index = start; index < end; index++) {
			address influencer = activeInfluencers[index];
			balances[indexArr] = referrerPlasma2Balances2key[influencer];
			influencers[indexArr] = influencer;
			indexArr++;
		}

		return (influencers, balances);
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



}
