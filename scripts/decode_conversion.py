# Constants
UINT_SIZE = 64
ADDRESS_SIZE = 40
BOOL_SIZE = 2

class Conversion(object):
    contractor = "0x"
    contractorProceedsETHWei = 0
    converter = "0x"
    state = 0
    conversionAmount = 0
    maxReferralRewardEthWei = 0
    maxReferralRewardTwoKey = 0
    moderatorFeeETHWei = 0
    baseTokenUnits = 0
    bonusTokenUnits = 0
    conversionCreatedAt = 0
    conversionExpiresAt = 0
    isConversionFiat = 0
    lockupAddress = "0x"

    # The class "constructor" - It's actually an initializer
    def __init__(self, contractor, contractorProceedsETHWei, converter, state, conversionAmount,
                maxReferralRewardEthWei, maxReferralRewardTwoKey, moderatorFeeETHWei, baseTokenUnits,
                bonusTokenUnits, conversionCreatedAt, conversionExpiresAt, isConversionFiat, lockupAddress):
        self.contractor = contractor #address
        self.contractorProceedsETHWei = contractorProceedsETHWei #uint256
        self.converter = converter #address
        self.state = state #bool
        self.conversionAmount = conversionAmount #uint256
        self.maxReferralRewardEthWei = maxReferralRewardEthWei #uint256
        self.maxReferralRewardTwoKey = maxReferralRewardTwoKey #uint256
        self.moderatorFeeETHWei = moderatorFeeETHWei #uint256
        self.baseTokenUnits = baseTokenUnits #uint256
        self.bonusTokenUnits = bonusTokenUnits #uint256
        self.conversionCreatedAt = conversionCreatedAt #uint256
        self.conversionExpiresAt = conversionExpiresAt #uint256
        self.isConversionFiat = isConversionFiat #bool
        self.lockupAddress = lockupAddress #address

    def __str__(self):
        return str(self.__class__) + ": " + str(self.__dict__)


# Helper functions
def fromWei(value):
    if(value == 0):
        return 0
    return value/(10**18)

def str_to_bool(value):
    value = int(value)
    if(value == 0):
        return False
    return True


# Function to decode input
def decode(conversion):
    values = []
    types =  ['address','uint','address','bool','uint','uint','uint','uint','uint','uint','uint','uint','bool','address']

    leading_zero = '0x'
    additional = 2
    index = 0
    for i in range(0,len(types)):
        if(i != 0):
            additional = 0
        if(types[i] == 'address'):
            prefix = ''
            if(additional == 0):
                prefix = '0x'
            values.append(prefix + conversion[index:index+ADDRESS_SIZE+additional])
            index = index + ADDRESS_SIZE + additional
        elif(types[i] == 'uint'):
            values.append(int(conversion[index:index+UINT_SIZE+additional],16))
            index = index + UINT_SIZE + additional
        elif(types[i] == 'bool'):
            values.append(conversion[index:index+BOOL_SIZE+additional])
            index = index + BOOL_SIZE + additional

    c = Conversion(values[0], fromWei(values[1]), values[2], values[3], fromWei(values[4]), fromWei(values[5]), fromWei(values[6]), fromWei(values[7]), fromWei(values[8]), fromWei(values[9]), values[10], values[11], str_to_bool(values[12]),values[13])
    return c

# conversion = '0xbae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d70000000000000000000000000000000000000000000000003997c30329df0000ebadf86c387fe3a4378738dba140da6ce014e974020000000000000000000000000000000000000000000000004563918244f400000000000000000000000000000000000000000000000000000a688906bd8b000000000000000000000000000000000000000000000000002acc25f4fa8755e50d000000000000000000000000000000000000000000000000016345785d8a00000000000000000000000000000000000000000000000000000de0b6b3a764000000000000000000000000000000000000000000000000000003311fc80a570000000000000000000000000000000000000000000000000000000000005c8f776f00000000000000000000000000000000000000000000000000000048c7fd376f000024409496e6cdf80fd6cb9489f53923faf80860'

# print(decode(conversion))

