export function requireWeb3(target: any, propertyKey: string, descriptor: PropertyDescriptor) {
    if (!target.web3 && !(target.base && target.base.web3)) {
        console.log(target);
        console.log(propertyKey);
        console.log(descriptor);
        throw new Error('Web3 instance required');
    }
    return descriptor;
}
