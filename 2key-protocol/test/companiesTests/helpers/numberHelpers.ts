// TODO: need to decide how we should round numbers for compare

export function prepareNumberForCompare(number: number) {
  return Number.parseFloat(
    number.toFixed(9)
  )
}

export function rewardCalc(reward: number, cutChain: Array<number>) {
  let resultReward = reward;

  for (let cutIndex = 0; cutIndex < cutChain.length; cutIndex += 1) {
    resultReward -= resultReward * cutChain[cutIndex]
  }

  return resultReward;
}

