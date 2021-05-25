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
export module OwnedDelegateUnstructuredProxy {
    export const contactName = "OwnedDelegateUnstructuredProxy";
    export const abi = '[{"inputs":[{"internalType":"address","name":"_delegateAddress","type":"address"}],"payable":false,"stateMutability":"nonpayable","type":"constructor"},{"payable":false,"stateMutability":"nonpayable","type":"fallback"},{"constant":true,"inputs":[],"name":"getDelegate","outputs":[{"internalType":"address","name":"delegate","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"getOwner","outputs":[{"internalType":"address","name":"owner","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"_delegateAddress","type":"address"}],"name":"setDelegate","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"}]';
    export const bytecode = '608060405234801561001057600080fd5b506040516108c63803806108c68339818101604052602081101561003357600080fd5b810190808051906020019092919050505073__$ecfb6c4d3c3ceff197e19e585a0a53728c$__6375d7bdef600073ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff16146100a06101ff60201b6105201760201c565b6040518363ffffffff1660e01b81526004018083151515158152602001806020018060200180602001848103845285818151815260200191508051906020019080838360005b838110156101015780820151818401526020810190506100e6565b50505050905090810190601f16801561012e5780820380516001836020036101000a031916815260200191505b508481038352602a81526020018061087a602a9139604001848103825260228152602001806108a4602291396040019550505050505060006040518083038186803b15801561017c57600080fd5b505af4158015610190573d6000803e3d6000fd5b505050506000604051808061085560259139602501905060405180910390209050600060405180807f414e3a2f2f636f6e74726163742f73746f726167652f6f776e65720000000000815250601b0190506040518091039020905060003390508383558082555050505061023c565b60606040518060400160405280600681526020017f4552523631310000000000000000000000000000000000000000000000000000815250905090565b61060a8061024b6000396000f3fe608060405234801561001057600080fd5b50600436106100415760003560e01c8063893d20e8146101d7578063bc7f3b5014610221578063ca5eb5e11461026b575b600061004b6102af565b905073__$ecfb6c4d3c3ceff197e19e585a0a53728c$__6375d7bdef600073ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff161461009f6102d5565b6040518363ffffffff1660e01b81526004018083151515158152602001806020018060200180602001848103845285818151815260200191508051906020019080838360005b838110156101005780820151818401526020810190506100e5565b50505050905090810190601f16801561012d5780820380516001836020036101000a031916815260200191505b50848103835260158152602001807f416273747261637444656c656761746550726f78790000000000000000000000815250602001848103825260298152602001806105ad602991396040019550505050505060006040518083038186803b15801561019857600080fd5b505af41580156101ac573d6000803e3d6000fd5b5050505060405136600082376000813683855af43d806000843e81600081146101d3578184f35b8184fd5b6101df610312565b604051808273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200191505060405180910390f35b6102296102af565b604051808273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200191505060405180910390f35b6102ad6004803603602081101561028157600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff169060200190929190505050610355565b005b600080604051808061058860259139602501905060405180910390209050805491505090565b60606040518060400160405280600681526020017f4552523630300000000000000000000000000000000000000000000000000000815250905090565b60008060405180807f414e3a2f2f636f6e74726163742f73746f726167652f6f776e65720000000000815250601b01905060405180910390209050805491505090565b73__$ecfb6c4d3c3ceff197e19e585a0a53728c$__6375d7bdef610377610312565b73ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff1614156103ae6104e3565b6040518363ffffffff1660e01b81526004018083151515158152602001806020018060200180602001848103845285818151815260200191508051906020019080838360005b8381101561040f5780820151818401526020810190506103f4565b50505050905090810190601f16801561043c5780820380516001836020036101000a031916815260200191505b508481038352602a81526020018061055e602a91396040018481038252601f8152602001807f546865206d73672e73656e646572206973206e6f7420746865206f776e6572008152506020019550505050505060006040518083038186803b1580156104a757600080fd5b505af41580156104bb573d6000803e3d6000fd5b5050505060006040518080610588602591396025019050604051809103902090508181555050565b60606040518060400160405280600681526020017f4552523430330000000000000000000000000000000000000000000000000000815250905090565b60606040518060400160405280600681526020017f455252363131000000000000000000000000000000000000000000000000000081525090509056fe4f776e656444656c6567617465556e7374727563747572656450726f78792e73657444656c6567617465414e3a2f2f636f6e74726163742f73746f726167652f64656c65676174652d74617267657444656c6567617465207461726765742061646472657373206d757374206e6f7420626520656d707479a265627a7a723158200c39c41907171396eb565e452def5204a96765bf02fda6513050ea8015e1b2bc64736f6c63430005110032414e3a2f2f636f6e74726163742f73746f726167652f64656c65676174652d7461726765744f776e656444656c6567617465556e7374727563747572656450726f78792e636f6e7374727563746f725f64656c656761746541646472657373206d757374206e6f7420626520656d707479';
    export const deployedBytecode = '608060405234801561001057600080fd5b50600436106100415760003560e01c8063893d20e8146101d7578063bc7f3b5014610221578063ca5eb5e11461026b575b600061004b6102af565b905073__$ecfb6c4d3c3ceff197e19e585a0a53728c$__6375d7bdef600073ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff161461009f6102d5565b6040518363ffffffff1660e01b81526004018083151515158152602001806020018060200180602001848103845285818151815260200191508051906020019080838360005b838110156101005780820151818401526020810190506100e5565b50505050905090810190601f16801561012d5780820380516001836020036101000a031916815260200191505b50848103835260158152602001807f416273747261637444656c656761746550726f78790000000000000000000000815250602001848103825260298152602001806105ad602991396040019550505050505060006040518083038186803b15801561019857600080fd5b505af41580156101ac573d6000803e3d6000fd5b5050505060405136600082376000813683855af43d806000843e81600081146101d3578184f35b8184fd5b6101df610312565b604051808273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200191505060405180910390f35b6102296102af565b604051808273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200191505060405180910390f35b6102ad6004803603602081101561028157600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff169060200190929190505050610355565b005b600080604051808061058860259139602501905060405180910390209050805491505090565b60606040518060400160405280600681526020017f4552523630300000000000000000000000000000000000000000000000000000815250905090565b60008060405180807f414e3a2f2f636f6e74726163742f73746f726167652f6f776e65720000000000815250601b01905060405180910390209050805491505090565b73__$ecfb6c4d3c3ceff197e19e585a0a53728c$__6375d7bdef610377610312565b73ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff1614156103ae6104e3565b6040518363ffffffff1660e01b81526004018083151515158152602001806020018060200180602001848103845285818151815260200191508051906020019080838360005b8381101561040f5780820151818401526020810190506103f4565b50505050905090810190601f16801561043c5780820380516001836020036101000a031916815260200191505b508481038352602a81526020018061055e602a91396040018481038252601f8152602001807f546865206d73672e73656e646572206973206e6f7420746865206f776e6572008152506020019550505050505060006040518083038186803b1580156104a757600080fd5b505af41580156104bb573d6000803e3d6000fd5b5050505060006040518080610588602591396025019050604051809103902090508181555050565b60606040518060400160405280600681526020017f4552523430330000000000000000000000000000000000000000000000000000815250905090565b60606040518060400160405280600681526020017f455252363131000000000000000000000000000000000000000000000000000081525090509056fe4f776e656444656c6567617465556e7374727563747572656450726f78792e73657444656c6567617465414e3a2f2f636f6e74726163742f73746f726167652f64656c65676174652d74617267657444656c6567617465207461726765742061646472657373206d757374206e6f7420626520656d707479a265627a7a723158200c39c41907171396eb565e452def5204a96765bf02fda6513050ea8015e1b2bc64736f6c63430005110032';
    export function deploy(client: Provider, commons_base_ErrorsLib_sol_ErrorsLib: string, _delegateAddress: string, withContractMeta: boolean = false): Promise<string> {
        const codec = client.contractCodec(abi);
        const links = [{ name: "$ecfb6c4d3c3ceff197e19e585a0a53728c$", address: commons_base_ErrorsLib_sol_ErrorsLib }];
        const linkedBytecode = linker(bytecode, links);
        const data = Buffer.concat([Buffer.from(linkedBytecode, "hex"), codec.encodeDeploy(_delegateAddress)]);
        return client.deploy(data, withContractMeta ? [{ abi: OwnedDelegateUnstructuredProxy.abi, codeHash: new Keccak(256).update(linker(OwnedDelegateUnstructuredProxy.deployedBytecode, links), "hex").digest("binary") }] : undefined);
    }
    export async function deployContract(client: Provider, commons_base_ErrorsLib_sol_ErrorsLib: string, _delegateAddress: string, withContractMeta: boolean = false): Promise<Contract> { const address = await deploy(client, commons_base_ErrorsLib_sol_ErrorsLib, _delegateAddress, withContractMeta); return contract(client, address); }
    export type Contract = ReturnType<typeof contract>;
    export const contract = (client: Provider, address: string) => ({ address, functions: { getDelegate(call = defaultCall): Promise<{
                delegate: string;
            }> {
                const data = encode(client).getDelegate();
                return call<{
                    delegate: string;
                }>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).getDelegate();
                });
            }, getOwner(call = defaultCall): Promise<{
                owner: string;
            }> {
                const data = encode(client).getOwner();
                return call<{
                    owner: string;
                }>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).getOwner();
                });
            }, setDelegate(_delegateAddress: string, call = defaultCall): Promise<void> {
                const data = encode(client).setDelegate(_delegateAddress);
                return call<void>(client, address, data, false, (data: Uint8Array | undefined) => {
                    return decode(client, data).setDelegate();
                });
            } } as const } as const);
    export const encode = (client: Provider) => { const codec = client.contractCodec(abi); return {
        getDelegate: () => { return codec.encodeFunctionData("BC7F3B50"); },
        getOwner: () => { return codec.encodeFunctionData("893D20E8"); },
        setDelegate: (_delegateAddress: string) => { return codec.encodeFunctionData("CA5EB5E1", _delegateAddress); }
    }; };
    export const decode = (client: Provider, data: Uint8Array | undefined, topics: Uint8Array[] = []) => { const codec = client.contractCodec(abi); return {
        getDelegate: (): {
            delegate: string;
        } => {
            const [delegate] = codec.decodeFunctionResult ("BC7F3B50", data);
            return { delegate: delegate };
        },
        getOwner: (): {
            owner: string;
        } => {
            const [owner] = codec.decodeFunctionResult ("893D20E8", data);
            return { owner: owner };
        },
        setDelegate: (): void => { return; }
    }; };
}