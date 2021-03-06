import * as chai from 'chai';
import { bytesToString } from '../lib/utils';
const { expect } = chai;

describe('UTILS', () => {
  it('Should correctly decode string', () => {
    const result = bytesToString(
      Buffer.from('64756D6D795461736B3100000000000000000000000000000000000000000000', 'hex'),
    );
    expect(result).to.equal('dummyTask1');
  }).timeout(10000);
});
