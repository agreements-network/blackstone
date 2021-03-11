import {UserAccount} from "../commons-auth/UserAccount.abi";
import {Client} from "./client";
import {Keccak} from 'sha3';
import {HexString} from "./types";

const GRPC_NOT_FOUND = 5;

const trimBufferPadding = (buf: Buffer) => {
  let lo = 0;
  let hi = buf.length;
  for (let i = 0; i < buf.length && buf[i] === 0; i += 1) {
    lo = i + 1;
  }
  for (let i = buf.length - 1; i > 0 && buf[i] === 0; i -= 1) {
    hi = i;
  }
  return buf.slice(lo, hi);
};

export function BytesFromString(str: string) {
  return Buffer.from(str, 'utf8');
}

export function BytesToString(data: Buffer) {
  return trimBufferPadding(data).toString('utf8');
}

export function DecodeHex(str: string) {
  return Buffer.from(str, 'hex');
}

export function EncodeHex(data: Buffer) {
  return data.toString('hex');
}

/**
 * Returns a promise to call the forwardCall function of the given userAddress to invoke the function encoded in the given payload on the provided target address and return the result bytes representation
 * The 'payload' parameter must be the output of calling the 'encode(...)' function on a contract's function. E.g. <contract>.<function>.encode(param1, param2)
 * 'shouldWaitForVent' is a boolean parameter which indicates whether this.callOnBehalfOf should to wait for vent db to catch up to the block height in the forwardCall response, before resolving the promise.
 */
export async function CallOnBehalfOf(client: Client, userAddress: string, targetAddress: string, payload: string): Promise<HexString> {
  const actingUser = new UserAccount.Contract(client, userAddress)
  return actingUser.forwardCall(targetAddress, DecodeHex(payload))
    .then(data => EncodeHex(trimBufferPadding(data.returnData)));
}

export async function GetFromNameRegistry(client: Client, name: string): Promise<string | void> {
  try {
    const entry = await client.namereg.get(name)
    return entry.getData()
  } catch (err) {
    if (err.code === GRPC_NOT_FOUND) {
      return undefined
    }
    throw err
  }
}

export async function SetToNameRegistry(client: Client, name: string, value: string): Promise<void> {
  await client.namereg.set(name, value)
}

export function SHA3(str: string) {
  const hash = (new Keccak(256)).update(str);
  return hash.digest('hex').toUpperCase();
}
