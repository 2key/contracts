pragma solidity ^0.4.24;

/**
 * @title Contract to handle accounting for two key campaigns
 * @author Nikola Madjarevic
 */
contract TwoKeyCampaignAccountant {

    address twoKeySingletonRegistry;

    mapping(address => UserCampaign[]) contractorToCampaigns;


    modifier onlyTwoKeySingletonRegistry {
        require(msg.sender == twoKeySingletonRegistry);
        _;
    }


    struct UserCampaign {
        bytes32 campaignVersion;
        uint campaignCreatedAt;
        address proxyAcquisitionCampaign;
        address proxyConversionHandler;
        address proxyLogicHandler;
    }


    constructor(address _twoKeySingletonRegistry) public {
        twoKeySingletonRegistry = _twoKeySingletonRegistry;
    }



    function addCampaignToUser(
        string memory _campaignVersion,
        uint _campaignCreatedAt,
        address _proxyAcquisitionCampaign,
        address _proxyConversionHandler,
        address _proxyLogicHandler,
        address contractor
    )
    public
    onlyTwoKeySingletonRegistry
    {
        bytes32 campaignVersion = stringToBytes32(_campaignVersion);
        UserCampaign memory userCampaign = UserCampaign(
            campaignVersion,
            _campaignCreatedAt,
            _proxyAcquisitionCampaign,
            _proxyConversionHandler,
            _proxyLogicHandler
        );

        contractorToCampaigns[contractor].push(userCampaign);

    }


    function getContractorCampaigns(
        address contractor
    )
    public
    view
    returns (bytes32[],uint[],address[])
    {
        UserCampaign[] memory campaigns = contractorToCampaigns[contractor];
        uint length = campaigns.length;

        bytes32 [] memory versions = new bytes32[](length);
        uint [] memory creationTimestamps = new uint[](length);
        address [] memory proxyAddresses = new address[](length*3); //Per object we have 3 addresses

        uint counter = 0;

        for(uint i=0; i<length; i++) {
            UserCampaign memory campaign = campaigns[i];

            versions[i] = campaign.campaignVersion;

            creationTimestamps[i] = campaign.campaignCreatedAt;

            proxyAddresses[counter] = campaign.proxyAcquisitionCampaign;
            proxyAddresses[counter+1] = campaign.proxyConversionHandler;
            proxyAddresses[counter+2] = campaign.proxyLogicHandler;

            counter += 3;
        }

        return (versions,creationTimestamps,proxyAddresses);
    }





    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }

}
