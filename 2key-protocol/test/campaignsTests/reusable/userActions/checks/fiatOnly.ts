export default function fiatOnly(isFiatOnly: boolean): void {
  if(!isFiatOnly){
    throw new Error('Unacceptable user action for not fiat campaign');
  }
}
