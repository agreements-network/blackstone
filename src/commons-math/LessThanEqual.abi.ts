//Code generated by solts. DO NOT EDIT.
import { Readable } from "stream";
import { Address, CancelStreamSignal, ContractCodec, Event, linker, listenerFor, Result, Keccak } from "@hyperledger/burrow";
interface Provider {
    deploy(data: string | Uint8Array, contractMeta?: {
        abi: string;
        codeHash: Uint8Array;
    }[]): Promise<Address>;
    call(data: string | Uint8Array, address: string): Promise<Uint8Array | undefined>;
    callSim(data: string | Uint8Array, address: string): Promise<Uint8Array | undefined>;
    listen(signatures: string[], address: string, callback: (err?: Error, event?: Event) => CancelStreamSignal | void, start?: "first" | "latest" | "stream" | number, end?: "first" | "latest" | "stream" | number): unknown;
    contractCodec(contractABI: string): ContractCodec;
}
export type Caller = typeof defaultCall;
export async function defaultCall<Output>(client: Provider, addr: string, data: Uint8Array, isSim: boolean, callback: (returnData: Uint8Array | undefined) => Output): Promise<Output> {
    const returnData = await (isSim ? client.callSim(data, addr) : client.call(data, addr));
    return callback(returnData);
}
export module LessThanEqual {
    export const contactName = "LessThanEqual";
    export const abi = '[{"constant":false,"inputs":[{"internalType":"address","name":"_piAddress","type":"address"},{"internalType":"bytes32","name":"_activityInstanceId","type":"bytes32"},{"internalType":"bytes32","name":"","type":"bytes32"},{"internalType":"address","name":"","type":"address"}],"name":"complete","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"}]';
    export const bytecode = '608060405234801561001057600080fd5b506102fb806100206000396000f3fe608060405234801561001057600080fd5b506004361061002b5760003560e01c8063867c715114610030575b600080fd5b6100a66004803603608081101561004657600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff1690602001909291908035906020019092919080359060200190929190803573ffffffffffffffffffffffffffffffffffffffff1690602001909291905050506100a8565b005b60008473ffffffffffffffffffffffffffffffffffffffff1663c2334a5a856040518263ffffffff1660e01b815260040180828152602001807f6e756d626572496e4f6e65000000000000000000000000000000000000000000815250602001915050602060405180830381600087803b15801561012557600080fd5b505af1158015610139573d6000803e3d6000fd5b505050506040513d602081101561014f57600080fd5b8101908080519060200190929190505050905060008573ffffffffffffffffffffffffffffffffffffffff1663c2334a5a866040518263ffffffff1660e01b815260040180828152602001807f6e756d626572496e54776f000000000000000000000000000000000000000000815250602001915050602060405180830381600087803b1580156101df57600080fd5b505af11580156101f3573d6000803e3d6000fd5b505050506040513d602081101561020957600080fd5b810190808051906020019092919050505090508573ffffffffffffffffffffffffffffffffffffffff16639cc222bd86838511156040518363ffffffff1660e01b815260040180838152602001807f726573756c7400000000000000000000000000000000000000000000000000008152506020018215151515815260200192505050600060405180830381600087803b1580156102a657600080fd5b505af11580156102ba573d6000803e3d6000fd5b5050505050505050505056fea265627a7a72315820acb20ade75c497b03555e849bc89fe3f3accfa695da420b57bb06a5970933c9864736f6c63430005110032';
    export const deployedBytecode = '608060405234801561001057600080fd5b506004361061002b5760003560e01c8063867c715114610030575b600080fd5b6100a66004803603608081101561004657600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff1690602001909291908035906020019092919080359060200190929190803573ffffffffffffffffffffffffffffffffffffffff1690602001909291905050506100a8565b005b60008473ffffffffffffffffffffffffffffffffffffffff1663c2334a5a856040518263ffffffff1660e01b815260040180828152602001807f6e756d626572496e4f6e65000000000000000000000000000000000000000000815250602001915050602060405180830381600087803b15801561012557600080fd5b505af1158015610139573d6000803e3d6000fd5b505050506040513d602081101561014f57600080fd5b8101908080519060200190929190505050905060008573ffffffffffffffffffffffffffffffffffffffff1663c2334a5a866040518263ffffffff1660e01b815260040180828152602001807f6e756d626572496e54776f000000000000000000000000000000000000000000815250602001915050602060405180830381600087803b1580156101df57600080fd5b505af11580156101f3573d6000803e3d6000fd5b505050506040513d602081101561020957600080fd5b810190808051906020019092919050505090508573ffffffffffffffffffffffffffffffffffffffff16639cc222bd86838511156040518363ffffffff1660e01b815260040180838152602001807f726573756c7400000000000000000000000000000000000000000000000000008152506020018215151515815260200192505050600060405180830381600087803b1580156102a657600080fd5b505af11580156102ba573d6000803e3d6000fd5b5050505050505050505056fea265627a7a72315820acb20ade75c497b03555e849bc89fe3f3accfa695da420b57bb06a5970933c9864736f6c63430005110032';
    export function deploy(client: Provider, withContractMeta: boolean = false): Promise<string> {
        const codec = client.contractCodec(abi);
        const data = Buffer.concat([Buffer.from(bytecode, "hex"), codec.encodeDeploy()]);
        return client.deploy(data, withContractMeta ? [{ abi: LessThanEqual.abi, codeHash: new Keccak(256).update(LessThanEqual.deployedBytecode, "hex").digest("binary") }] : undefined);
    }
    export async function deployContract(client: Provider, withContractMeta: boolean = false): Promise<Contract> { const address = await deploy(client, withContractMeta); return contract(client, address); }
    export type Contract = ReturnType<typeof contract>;
    export const contract = (client: Provider, address: string) => ({ address, functions: { complete(_piAddress: string, _activityInstanceId: Buffer, call = defaultCall): Promise<void> {
                const data = encode(client).complete(_piAddress, _activityInstanceId);
                return call<void>(client, address, data, false, (data: Uint8Array | undefined) => {
                    return decode(client, data).complete();
                });
            } } as const } as const);
    export const encode = (client: Provider) => { const codec = client.contractCodec(abi); return {
        complete: (_piAddress: string, _activityInstanceId: Buffer) => { return codec.encodeFunctionData("867C7151", _piAddress, _activityInstanceId); }
    }; };
    export const decode = (client: Provider, data: Uint8Array | undefined, topics: Uint8Array[] = []) => { const codec = client.contractCodec(abi); return {
        complete: (): void => { return; }
    }; };
}