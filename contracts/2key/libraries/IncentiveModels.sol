pragma solidity ^0.4.24;

import "./SafeMath.sol";

/**
 * @author Nikola Madjarevic
 */
library IncentiveModels {
    using SafeMath for uint;
    /**
     * @notice Implementation of average incentive model, reward is splited equally per referrer
     * @param totalBounty is total reward for the influencers
     * @param numberOfInfluencers is how many influencers we're splitting reward between
     */
    function averageModelRewards(
        uint totalBounty,
        uint numberOfInfluencers
    ) internal pure returns (uint) {
        if(numberOfInfluencers > 0) {
            uint equalPart = totalBounty.div(numberOfInfluencers);
            return equalPart;
        }
        return 0;
    }

    /**
     * @notice Implementation similar to average incentive model, except direct referrer) - gets 3x as the others
     * @param totalBounty is total reward for the influencers
     * @param numberOfInfluencers is how many influencers we're splitting reward between
     * @return two values, first is reward per regular referrer, and second is reward for last referrer in the chain
     */
    function averageLast3xRewards(
        uint totalBounty,
        uint numberOfInfluencers
    ) internal pure returns (uint,uint) {
        if(numberOfInfluencers> 0) {
            uint rewardPerReferrer = totalBounty.div(numberOfInfluencers.add(2));
            uint rewardForLast = rewardPerReferrer.mul(3);
            return (rewardPerReferrer, rewardForLast);
        }
        return (0,0);
    }

    /**
     * @notice Function to return array of corresponding values with rewards in power law schema
     * @param totalBounty is totalReward
     * @param numberOfInfluencers is the total number of influencers
     * @return rewards in wei
     */
    function powerLawRewards(
        uint totalBounty,
        uint numberOfInfluencers,
        uint factor
    ) internal pure returns (uint[]) {
        uint[] memory rewards = new uint[](numberOfInfluencers);
        if(numberOfInfluencers > 0) {
            uint x = calculateX(totalBounty,numberOfInfluencers,factor);
            for(uint i=0; i<numberOfInfluencers;i++) {
                rewards[numberOfInfluencers.sub(i.add(1))] = x.div(factor**i);
            }
        }
        return rewards;
    }


    /**
     * @notice Function to calculate base for all rewards in power law model
     * @param sumWei is the total reward to be splited in Wei
     * @param numberOfElements is the number of referrers in the chain
     * @return wei value of base for the rewards in power law
     */
    function calculateX(
        uint sumWei,
        uint numberOfElements,
        uint factor
    ) private pure returns (uint) {
        uint a = 1;
        uint sumOfFactors = 1;
        for(uint i=1; i<numberOfElements; i++) {
            a = a.mul(factor);
            sumOfFactors = sumOfFactors.add(a);
        }
        return sumWei.mul(a).div(sumOfFactors);
    }
}
