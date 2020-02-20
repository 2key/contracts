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

	uint public rate2KeyBoughtAt;

	bytes32 public merkleRoot;

	address public mirrorCampaignOnPlasma; // Address of campaign deployed to plasma network

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
	uint public moderatorEarnings;

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

	function rebalanceRates()
	public
	onlyMaintainer
	{
		// Function which will be used to rebalance rates

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
		}
	}

	/**
	 * @notice Function where maintainer can push earnings of moderator for the campaign
	 * @param _moderatorEarnings is the amount of 2key tokens earned by moderator
	 */
	function pushModeratorEarnings(
		uint _moderatorEarnings
	)
	public
	onlyMaintainer
	{
		moderatorEarnings = _moderatorEarnings;

		address twoKeyAdmin = getAddressFromTwoKeySingletonRegistry("TwoKeyAdmin");

		//Send 2key tokens to moderator
		transfer2KEY(twoKeyAdmin, _moderatorEarnings);

		// Update moderator on received tokens so it can proceed distribution to TwoKeyDeepFreezeTokenPool
		ITwoKeyAdmin(twoKeyAdmin).updateReceivedTokensAsModerator(moderatorEarnings);
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



	function submitProofAndWithdrawRewards(
		bytes32 [] proof,
		uint amount
	)
	public
	{
		address influencerPlasma = twoKeyEventSource.plasmaOf(msg.sender);

		//Validating that this is the amount he earned
		require(checkMerkleProof(influencerPlasma,proof,amount), 'proof is invalid');

		//Assuming that msg.sender is influencer
		require(areRewardsWithdrawn[msg.sender] == false); //He can't take reward twice

		payFeeForRegistration(influencerPlasma, amount);
	}


}
