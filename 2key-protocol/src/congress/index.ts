import {ITwoKeyBase, ITwoKeyHelpers} from '../interfaces';
import {ITwoKeyCongress} from './interfaces';

export default class TwoKeyCongress implements ITwoKeyCongress {
    private readonly base: ITwoKeyBase;
    private readonly helpers: ITwoKeyHelpers;
    // private readonly utils: ITwoKeyUtils;

    constructor(twoKeyProtocol: ITwoKeyBase, helpers: ITwoKeyHelpers) {
        this.base = twoKeyProtocol;
        this.helpers = helpers;
        // this.utils = utils;
    }
}