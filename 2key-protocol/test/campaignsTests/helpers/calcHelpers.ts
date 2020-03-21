export function calcUnlockingDates(distributionSeconds, portionsQty, interval, shift, withBase) {
  const resultDates = [];

  if (!withBase) {
    resultDates.push(distributionSeconds);
  }

  let lastSecondsPoint = distributionSeconds;

  if (!withBase) {
    lastSecondsPoint += shift
  }

  for (let i = 0; i < portionsQty; i += 1) {
    resultDates.push(lastSecondsPoint + interval * i);
  }

  return resultDates;
}


export function calcWithdrawAmounts(
  baseAmount: number,
  bonusAmount: number,
  portionsQty: number,
  withBase: boolean,
) {
  const portionsAmount = withBase ? (baseAmount + bonusAmount) : bonusAmount;
  const resultAmount = new Array(portionsQty).fill(portionsAmount / portionsQty);

  if (!withBase) {
    resultAmount.unshift(baseAmount);
  }

  return resultAmount;
}
