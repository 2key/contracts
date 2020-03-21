export default function kycRequired(isKycRequired: boolean): void {
  if(!isKycRequired){
    throw new Error('Unacceptable user action for campaign without KYC');
  }
}
