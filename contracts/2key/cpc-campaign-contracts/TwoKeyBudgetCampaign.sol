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

    // Merkle root
	bytes32 public merkleRoot;
    // Address of campaign deployed to plasma network
	address public mirrorCampaignOnPlasma;
	// Flag to determine if campaign is validated
	bool public isValidated;
	//Active influencer means that he has at least on participation in successful conversion
	address[] activeInfluencers;
	// Mapping active influencers
	mapping(address => bool) isActiveInfluencer;
	// His index position in the array
	mapping(address => uint) activeInfluencer2idx;
	//Selector if inventory is added
	bool isInventoryAdded;
	// Mapping representing if rewards are withdrawn
	mapping(address => bool) areRewardsWithdrawn;
	// Dollar to 2key rate in WEI at the moment of adding inventory
	uint public usd2KEYrateWei;
	// Variable to let us know if rewards have been bought with Ether
	bool public boughtRewardsWithEther;
	// Bounty how contractor wants referrers to split per conversion
	uint public bountyPerConversion;
	//Amount for rewards inventory
	uint public rewardsInventoryAmount;
	// Amount representing how much moderator has earned
	uint public moderatorTotalEarnings;
	// Amount representing how much moderator has now
	uint public moderatorEarningsBalance;


	/**
     * @notice Function to validate that contracts plasma and public are well mirrored
     */
	function validateContractFromMaintainer()
	public
	onlyMaintainer
	{
		isValidated = true;
	}


	/**
     * @notice Internal function to check the balance of the specific ERC20 on this contract
     */
	function getTokenBalance()
	internal
	view
	returns (uint)
	{
		return IERC20(twoKeyEconomy).balanceOf(address(this));
	}

	function transfer2KEY(
		address receiver,
		uint amount
	)
	internal
	{
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
		require(isInventoryAdded == false);

		boughtRewardsWithEther = true;
		rewardsInventoryAmount = buyTokensFromUpgradableExchange(msg.value, address(this));


		uint rateUsdToEth = ITwoKeyExchangeRateContract(getAddressFromTwoKeySingletonRegistry("TwoKeyExchangeRateContract")).getBaseToTargetRate("USD");
		usd2KEYrateWei = (msg.value).mul(rateUsdToEth).div(rewardsInventoryAmount);

		isInventoryAdded = true;
	}

    function rebalanceRatesModerator()
    public
    onlyMaintainer
    {

    }

    function rebalanceRatesInfluencers()
    public
    onlyMaintainer
    {
        address twoKeyUpgradableExchange = getAddressFromTwoKeySingletonRegistry("TwoKeyUpgradableExchange");
        // Function which will be used to rebalance rates
        uint usd2KEYRateWeiNow = IUpgradableExchange(twoKeyUpgradableExchange).sellRate2key();

		/**
		 * Explanation of algorithm:
		 *	________________________
		 *   25 2key |  1.5$  | 0.06$
		 *    X 2key |  1.5$  | 0.12$
	 	 *
		 *	25 2KEY * 0.06$ = X 2KEY * 0.12$
		 *
		 *   ==> X 2KEY = (25 2KEY * 0.06$) / (0.12$)
		 *   ==> X 2KEY = 1.5 2KEY $ / (0.12$)
		 *   ==> X 2KEY = 12.5 2KEY
		 */
        //Now check if rate went up
        if(usd2KEYRateWeiNow > usd2KEYrateWei) {
            uint tokensToBeGivenBackToExchange = reduceBalance(usd2KEYRateWeiNow);
			// Approve upgradable exchange to take leftover back
            IERC20(twoKeyEconomy).approve(twoKeyUpgradableExchange, tokensToBeGivenBackToExchange);
			// Call the function to release all DAI for this contract to reserve and to take approved amount of 2key back to liquidity pool
			IUpgradableExchange(twoKeyUpgradableExchange).returnLeftoverAfterRebalancing(tokensToBeGivenBackToExchange);
            // Reduce the reserved amount for the amount we're returning back
            reservedAmount2keyForRewards = reservedAmount2keyForRewards.sub(tokensToBeGivenBackToExchange);
        }
        // Check if rate went down
        else if(usd2KEYRateWeiNow < usd2KEYrateWei) {
            uint tokensToBeTakenFromExchange = increaseBalance(usd2KEYRateWeiNow);
            // Get more tokens we need
            IUpgradableExchange(twoKeyUpgradableExchange).getMore2KeyTokensForRebalancing(tokensToBeTakenFromExchange);
            // Increase reserved amount of tokens for the rewards
            reservedAmount2keyForRewards = reservedAmount2keyForRewards.add(tokensToBeTakenFromExchange);
        }
    }


    /**
     * @notice Function which will reduce influencers balance in case 2key rate went up
     * @param newRate is the new rate of 2key token
     */
    function reduceBalance(
        uint newRate
    )
    internal
    returns (uint)
    {
        uint amountToReturnToExchange;

        for(uint i=0; i<activeInfluencers.length; i++) {
			//Taking current influencer balance in 2key
            uint balance = referrerPlasma2Balances2key[activeInfluencers[i]];

			// Computing the new balance for the influencer
            uint newBalance = balance.mul(usd2KEYrateWei).div(newRate);

			// Assigning new balance to the influencer
            referrerPlasma2Balances2key[activeInfluencers[i]] = newBalance;

			// Amount to return
            amountToReturnToExchange = amountToReturnToExchange.add(balance.sub(newBalance));
        }

        return amountToReturnToExchange;
    }

    /**
     * @notice Function which will increase influencers balance in case 2key rate went down
     * @param newRate is the new rate of 2key token
     */
    function increaseBalance(
        uint newRate
    )
    internal
    returns (uint)
    {
        uint amountToGetFromExchange;

        for(uint i=0; i<activeInfluencers.length; i++) {
            uint balance = referrerPlasma2Balances2key[activeInfluencers[i]];

            uint newBalance = balance.mul(usd2KEYrateWei).div(newRate);
            referrerPlasma2Balances2key[activeInfluencers[i]] = newBalance;

            amountToGetFromExchange = amountToGetFromExchange.add(newBalance.sub(balance));
        }

        return amountToGetFromExchange;
    }


    /**
     * @notice Function to distribute rewards between all the influencers
     * which have earned the reward once campaign is done
     * @param influencers is the array of influencers
     */
	function distributeRewardsBetweenInfluencers(
		address [] influencers
	)
	public
	onlyMaintainer
	{
		for(uint i=0; i<influencers.length; i++) {
			if(areRewardsWithdrawn[influencers[i]]) {
				// Get the influencer balance
				uint balance = referrerPlasma2Balances2key[influencers[i]];
				// Set balance to be 0
				referrerPlasma2Balances2key[influencers[i]] = 0;
                // Reduce reserved amount for rewards
                reservedAmount2keyForRewards = reservedAmount2keyForRewards.sub(balance);
				// Pay fee
				payFeeForRegistration(influencers[i], balance);
			}
		}
	}


	/**
	 * @notice Wrapper function to pay the registration fee
	 * @param influencerPlasma is the plasma address of the influencer
	 * @param balance is the balance influencer earned
	 */
	function payFeeForRegistration(
		address influencerPlasma,
		uint balance
	)
	internal
	{
		// Get the address of TwoKeyFeeManager contract
		address twoKeyFeeManager = getAddressFromTwoKeySingletonRegistry("TwoKeyFeeManager");
		// Approve twoKeyFeeManager to take 2key tokens in amount of balance from this contract
		IERC20(twoKeyEconomy).approve(twoKeyFeeManager, balance);
		// Pay debt, Fee manager will keep the debt and forward leftover to the influencer
		ITwoKeyFeeManager(twoKeyFeeManager).payDebtWith2Key(
			twoKeyEventSource.ethereumOf(influencerPlasma),
			influencerPlasma,
			balance
		);

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
		require(isInventoryAdded == false);
		require(getTokenBalance() == _amount);

		rewardsInventoryAmount = _amount;
		isInventoryAdded = true;
	}


	/**
     * @notice Function to withdraw remaining rewards inventory in the contract
     */
	function withdrawRemainingRewardsInventory()
    public
    onlyContractor
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

	/**
	 * @notice validate a merkle proof.
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
     * @notice set a merkle root of the amount each (active) influencer received.
     *         (active influencer is an influencer that received a bounty)
     *         the idea is that the contractor calls computeMerkleRoot on plasma and then set the value manually
     */
	function setMerkleRoot(
		bytes32 _merkleRoot
	)
	public
	onlyMaintainer
	{
		require(merkleRoot == 0, 'merkle root already defined');
		merkleRoot = _merkleRoot;
	}


	/**
     * @notice Allow maintainers to push balances table
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
				activeInfluencer2idx[influencers[i]] = activeInfluencers.length;
				activeInfluencers.push(influencers[i]);
				isActiveInfluencer[influencers[i]] = true;
			}
			referrerPlasma2Balances2key[influencers[i]] = referrerPlasma2Balances2key[influencers[i]].add(balances[i]);
			reservedAmount2keyForRewards = reservedAmount2keyForRewards.add(balances[i]);
		}
	}

	/**
	 * @notice Function to set moderator earnings for the campaign
	 * @param totalEarnings is the total amount of 2KEY tokens moderator earned
	 * This function can be called only once.
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
	 * @notice Function where maintainer can push earnings of moderator for the campaign
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
		for(index = start; index < end; index++) {
			address influencer = activeInfluencers[index];
			balances[index] = referrerPlasma2Balances2key[influencer];
			influencers[index] = influencer;
		}

		return (influencers, balances);
	}


	function getPlasmaOf(address _a)
	internal
	view
	returns (address)
	{
		return twoKeyEventSource.plasmaOf(_a);
	}



//	function submitProofAndWithdrawRewards(
//		bytes32 [] proof,
//		uint amount
//	)
//	public
//	{
//		address influencerPlasma = twoKeyEventSource.plasmaOf(msg.sender);
//
//		//Validating that this is the amount he earned
//		require(checkMerkleProof(influencerPlasma,proof,amount), 'proof is invalid');
//
//		//Assuming that msg.sender is influencer
//		require(areRewardsWithdrawn[msg.sender] == false); //He can't take reward twice
//
//		payFeeForRegistration(influencerPlasma, amount);
//	}


}
