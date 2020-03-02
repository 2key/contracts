import {expect} from 'chai';

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

const tolerance = 0.01;

export function expectEqualNumbers(value: number, compareWith: number){
  expect(value)
    .to.be.lte(compareWith + tolerance)
    .to.be.gte(compareWith - tolerance)
}
