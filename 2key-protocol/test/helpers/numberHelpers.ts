import {expect} from 'chai';


export function rewardCalc(reward: number, cutChain: Array<number>) {
  let resultReward = reward;

  for (let cutIndex = 0; cutIndex < cutChain.length; cutIndex += 1) {
    resultReward -= resultReward * cutChain[cutIndex]
  }

  return resultReward;
}

const tolerance = 0.01;

export function expectEqualNumbers(value: number, compareWith: number, message?: string){
  expect(value, message)
    .to.be.lte(compareWith + tolerance)
    .to.be.gte(compareWith - tolerance)
}
