//Code generated by solts. DO NOT EDIT.
import { Readable } from "stream";
interface Provider<Tx> {
    deploy(msg: Tx, callback: (err: Error, addr: Uint8Array) => void): void;
    call(msg: Tx, callback: (err: Error, exec: Uint8Array) => void): void;
    callSim(msg: Tx, callback: (err: Error, exec: Uint8Array) => void): void;
    listen(signature: string, address: string, callback: (err: Error, event: any) => void): Readable;
    payload(data: string, address?: string): Tx;
    encode(name: string, inputs: string[], ...args: any[]): string;
    decode(data: Uint8Array, outputs: string[]): any;
}
function Call<Tx, Output>(client: Provider<Tx>, addr: string, data: string, isSim: boolean, callback: (exec: Uint8Array) => Output): Promise<Output> {
    const payload = client.payload(data, addr);
    if (isSim)
        return new Promise((resolve, reject) => { client.callSim(payload, (err, exec) => { err ? reject(err) : resolve(callback(exec)); }); });
    else
        return new Promise((resolve, reject) => { client.call(payload, (err, exec) => { err ? reject(err) : resolve(callback(exec)); }); });
}
function Replace(bytecode: string, name: string, address: string): string {
    address = address + Array(40 - address.length + 1).join("0");
    const truncated = name.slice(0, 36);
    const label = "__" + truncated + Array(37 - truncated.length).join("_") + "__";
    while (bytecode.indexOf(label) >= 0)
        bytecode = bytecode.replace(label, address);
    return bytecode;
}
export module AgreementRequestResponse {
    export function Deploy<Tx>(client: Provider<Tx>, _owner: string): Promise<string> {
        let bytecode = "608060405234801561001057600080fd5b506040516111d73803806111d78339818101604052602081101561003357600080fd5b810190808051906020019092919050505080600460006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555050611142806100956000396000f3fe60806040526004361061004a5760003560e01c80630d1b80aa1461004f5780630d3ab153146100e157806372718abd146101995780639d8d60a7146101c4578063f86325ed14610377575b600080fd5b34801561005b57600080fd5b506100df600480360360a081101561007257600080fd5b8101908080359060200190929190803573ffffffffffffffffffffffffffffffffffffffff169060200190929190803573ffffffffffffffffffffffffffffffffffffffff169060200190929190803560ff169060200190929190803590602001909291905050506103a2565b005b610197600480360360e08110156100f757600080fd5b8101908080359060200190929190803573ffffffffffffffffffffffffffffffffffffffff16906020019092919080359060200190929190803567ffffffffffffffff169060200190929190803573ffffffffffffffffffffffffffffffffffffffff169060200190929190803573ffffffffffffffffffffffffffffffffffffffff1690602001909291908035151590602001909291905050506106ea565b005b3480156101a557600080fd5b506101ae610c2c565b6040518082815260200191505060405180910390f35b3480156101d057600080fd5b50610375600480360360c08110156101e757600080fd5b8101908080359060200190929190803573ffffffffffffffffffffffffffffffffffffffff1690602001909291908035906020019064010000000081111561022e57600080fd5b82018360208201111561024057600080fd5b8035906020019184600183028401116401000000008311171561026257600080fd5b91908080601f016020809104026020016040519081016040528093929190818152602001838380828437600081840152601f19601f820116905080830192505050505050509192919290803573ffffffffffffffffffffffffffffffffffffffff169060200190929190803590602001906401000000008111156102e557600080fd5b8201836020820111156102f757600080fd5b8035906020019184600183028401116401000000008311171561031957600080fd5b91908080601f016020809104026020016040519081016040528093929190818152602001838380828437600081840152601f19601f82011690508083019250505050505050919291929080359060200190929190505050610c31565b005b34801561038357600080fd5b5061038c611063565b6040518082815260200191505060405180910390f35b600460009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff1614610465576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040180806020018281038252601d8152602001807f53656e646572206d75737420626520636f6e7472616374206f776e657200000081525060200191505060405180910390fd5b60026040518060e001604052808781526020018673ffffffffffffffffffffffffffffffffffffffff1681526020018573ffffffffffffffffffffffffffffffffffffffff1681526020018460ff168152602001438152602001838152602001600354815250908060018154018082558091505090600182039060005260206000209060060201600090919290919091506000820151816000015560208201518160010160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555060408201518160020160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555060608201518160020160146101000a81548160ff021916908360ff1602179055506080820151816003015560a0820151816004015560c08201518160050155505050847f7265706f72743a61677265656d656e742d73746174652d6368616e67650000007f6d6f6e61780000000000000000000000000000000000000000000000000000007f064aad62e0efce0ebd2d6e7d9cf163ab27a057be205805aae66cd422af01447b8787874388600354604051808773ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020018673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020018560ff1660ff168152602001848152602001838152602001828152602001965050505050505060405180910390a460016003600082825401925050819055505050505050565b8060006001905081156106fe576001810190505b803410610773576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004018080602001828103825260128152602001807f496e73756666696369656e742066756e6473000000000000000000000000000081525060200191505060405180910390fd5b60006040518061018001604052803373ffffffffffffffffffffffffffffffffffffffff1681526020013273ffffffffffffffffffffffffffffffffffffffff1681526020018b81526020018a73ffffffffffffffffffffffffffffffffffffffff1681526020018981526020018867ffffffffffffffff1681526020018773ffffffffffffffffffffffffffffffffffffffff1681526020018673ffffffffffffffffffffffffffffffffffffffff168152602001851515815260200143815260200160008054905081526020016003548152509080600181540180825580915050906001820390600052602060002090600a02016000909192909190915060008201518160000160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555060208201518160010160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055506040820151816002015560608201518160030160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055506080820151816004015560a08201518160050160006101000a81548167ffffffffffffffff021916908367ffffffffffffffff16021790555060c08201518160050160086101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555060e08201518160060160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055506101008201518160060160146101000a81548160ff0219169083151502179055506101208201518160070155610140820151816008015561016082015181600901555050503373ffffffffffffffffffffffffffffffffffffffff167f726571756573743a6372656174652d61677265656d656e7400000000000000007f6d6f6e61780000000000000000000000000000000000000000000000000000007fab8c26448560548bcdad0d7d6040d27c2b1c0fd84aff8a904f079783552168df328d8d8d8d8d8d8d43600160008054905003600354604051808c73ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020018b81526020018a73ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020018981526020018867ffffffffffffffff1667ffffffffffffffff1681526020018773ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020018673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001851515151581526020018481526020018381526020018281526020019b50505050505050505050505060405180910390a46001600360008282540192505081905550505050505050505050565b600181565b600460009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff1614610cf4576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040180806020018281038252601d8152602001807f53656e646572206d75737420626520636f6e7472616374206f776e657200000081525060200191505060405180910390fd5b60016040518061010001604052808881526020018773ffffffffffffffffffffffffffffffffffffffff1681526020018681526020018573ffffffffffffffffffffffffffffffffffffffff168152602001848152602001438152602001838152602001600354815250908060018154018082558091505090600182039060005260206000209060080201600090919290919091506000820151816000015560208201518160010160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055506040820151816002019080519060200190610df6929190611068565b5060608201518160030160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055506080820151816004019080519060200190610e5a929190611068565b5060a0820151816005015560c0820151816006015560e08201518160070155505050857f7265706f72743a61677265656d656e742d6372656174696f6e000000000000007f6d6f6e61780000000000000000000000000000000000000000000000000000007ffec27c7f751c6597aacdb3a1827be7b1eddea09daeb56f1b4fd2dea872ab3f59888888884389600354604051808873ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001806020018773ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200180602001868152602001858152602001848152602001838103835289818151815260200191508051906020019080838360005b83811015610fa3578082015181840152602081019050610f88565b50505050905090810190601f168015610fd05780820380516001836020036101000a031916815260200191505b50838103825287818151815260200191508051906020019080838360005b83811015611009578082015181840152602081019050610fee565b50505050905090810190601f1680156110365780820380516001836020036101000a031916815260200191505b50995050505050505050505060405180910390a46001600360008282540192505081905550505050505050565b600181565b828054600181600116156101000203166002900490600052602060002090601f016020900481019282601f106110a957805160ff19168380011785556110d7565b828001600101855582156110d7579182015b828111156110d65782518255916020019190600101906110bb565b5b5090506110e491906110e8565b5090565b61110a91905b808211156111065760008160009055506001016110ee565b5090565b9056fea265627a7a72315820a11f4d0c9b792dceee7019140480f0df9ae0ee4fab45f7de4cc08192402a18a864736f6c634300050c0032";
        const data = bytecode + client.encode("", ["address"], _owner);
        const payload = client.payload(data);
        return new Promise((resolve, reject) => { client.deploy(payload, (err, addr) => {
            if (err)
                reject(err);
            else {
                const address = Buffer.from(addr).toString("hex").toUpperCase();
                resolve(address);
            }
        }); });
    }
    export class Contract<Tx> {
        private client: Provider<Tx>;
        public address: string;
        constructor(client: Provider<Tx>, address: string) {
            this.client = client;
            this.address = address;
        }
        LogReportAgreementCreation(callback: (err: Error, event: any) => void): Readable { return this.client.listen("LogReportAgreementCreation", this.address, callback); }
        LogReportAgreementStateChange(callback: (err: Error, event: any) => void): Readable { return this.client.listen("LogReportAgreementStateChange", this.address, callback); }
        LogRequestCreateAgreement(callback: (err: Error, event: any) => void): Readable { return this.client.listen("LogRequestCreateAgreement", this.address, callback); }
        BASE_PRICE() {
            const data = Encode(this.client).BASE_PRICE();
            return Call<Tx, [number]>(this.client, this.address, data, true, (exec: Uint8Array) => {
                return Decode(this.client, exec).BASE_PRICE();
            });
        }
        STATE_CHANGE_REPORT_PRICE() {
            const data = Encode(this.client).STATE_CHANGE_REPORT_PRICE();
            return Call<Tx, [number]>(this.client, this.address, data, true, (exec: Uint8Array) => {
                return Decode(this.client, exec).STATE_CHANGE_REPORT_PRICE();
            });
        }
        reportAgreementCreation(tokenId: number, tokenContractAddress: string, errorCode: string, agreement: string, permalink: string, requestIndex: number) {
            const data = Encode(this.client).reportAgreementCreation(tokenId, tokenContractAddress, errorCode, agreement, permalink, requestIndex);
            return Call<Tx, void>(this.client, this.address, data, false, (exec: Uint8Array) => {
                return Decode(this.client, exec).reportAgreementCreation();
            });
        }
        reportAgreementStateChange(tokenId: number, tokenContractAddress: string, agreement: string, state: number, requestIndex: number) {
            const data = Encode(this.client).reportAgreementStateChange(tokenId, tokenContractAddress, agreement, state, requestIndex);
            return Call<Tx, void>(this.client, this.address, data, false, (exec: Uint8Array) => {
                return Decode(this.client, exec).reportAgreementStateChange();
            });
        }
        requestCreateAgreement(tokenId: number, tokenContractAddress: string, templateId: Buffer, templateConfig: number, seller: string, buyer: string, stateChangeReport: boolean) {
            const data = Encode(this.client).requestCreateAgreement(tokenId, tokenContractAddress, templateId, templateConfig, seller, buyer, stateChangeReport);
            return Call<Tx, void>(this.client, this.address, data, false, (exec: Uint8Array) => {
                return Decode(this.client, exec).requestCreateAgreement();
            });
        }
    }
    export const Encode = <Tx>(client: Provider<Tx>) => { return {
        BASE_PRICE: () => { return client.encode("F86325ED", []); },
        STATE_CHANGE_REPORT_PRICE: () => { return client.encode("72718ABD", []); },
        reportAgreementCreation: (tokenId: number, tokenContractAddress: string, errorCode: string, agreement: string, permalink: string, requestIndex: number) => { return client.encode("9D8D60A7", ["uint256", "address", "string", "address", "string", "uint256"], tokenId, tokenContractAddress, errorCode, agreement, permalink, requestIndex); },
        reportAgreementStateChange: (tokenId: number, tokenContractAddress: string, agreement: string, state: number, requestIndex: number) => { return client.encode("0D1B80AA", ["uint256", "address", "address", "uint8", "uint256"], tokenId, tokenContractAddress, agreement, state, requestIndex); },
        requestCreateAgreement: (tokenId: number, tokenContractAddress: string, templateId: Buffer, templateConfig: number, seller: string, buyer: string, stateChangeReport: boolean) => { return client.encode("0D3AB153", ["uint256", "address", "bytes32", "uint64", "address", "address", "bool"], tokenId, tokenContractAddress, templateId, templateConfig, seller, buyer, stateChangeReport); }
    }; };
    export const Decode = <Tx>(client: Provider<Tx>, data: Uint8Array) => { return {
        BASE_PRICE: (): [number] => { return client.decode(data, ["uint256"]); },
        STATE_CHANGE_REPORT_PRICE: (): [number] => { return client.decode(data, ["uint256"]); },
        reportAgreementCreation: (): void => { return; },
        reportAgreementStateChange: (): void => { return; },
        requestCreateAgreement: (): void => { return; }
    }; };
}