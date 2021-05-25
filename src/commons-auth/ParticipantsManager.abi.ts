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
export module ParticipantsManager {
    export const contactName = "ParticipantsManager";
    export const abi = '[{"constant":true,"inputs":[],"name":"ERC165_ID_ObjectFactory","outputs":[{"internalType":"bytes4","name":"","type":"bytes4"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"ERC165_ID_Upgradeable","outputs":[{"internalType":"bytes4","name":"","type":"bytes4"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"ERC165_ID_VERSIONED_ARTIFACT","outputs":[{"internalType":"bytes4","name":"","type":"bytes4"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"OBJECT_CLASS_ORGANIZATION","outputs":[{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"OBJECT_CLASS_USER_ACCOUNT","outputs":[{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"_other","type":"address"}],"name":"compareArtifactVersion","outputs":[{"internalType":"int256","name":"result","type":"int256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"uint8[3]","name":"_version","type":"uint8[3]"}],"name":"compareArtifactVersion","outputs":[{"internalType":"int256","name":"result","type":"int256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address[]","name":"_initialApprovers","type":"address[]"}],"name":"createOrganization","outputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"address","name":"","type":"address"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"bytes32","name":"_id","type":"bytes32"},{"internalType":"address","name":"_owner","type":"address"},{"internalType":"address","name":"_ecosystem","type":"address"}],"name":"createUserAccount","outputs":[{"internalType":"address","name":"userAccount","type":"address"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"_organization","type":"address"},{"internalType":"bytes32","name":"_departmentId","type":"bytes32"}],"name":"departmentExists","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"_organization","type":"address"},{"internalType":"uint256","name":"_pos","type":"uint256"}],"name":"getApproverAtIndex","outputs":[{"internalType":"address","name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"_organization","type":"address"},{"internalType":"address","name":"_approver","type":"address"}],"name":"getApproverData","outputs":[{"internalType":"address","name":"approverAddress","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"getArtifactVersion","outputs":[{"internalType":"uint8[3]","name":"","type":"uint8[3]"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"getArtifactVersionMajor","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"getArtifactVersionMinor","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"getArtifactVersionPatch","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"_organization","type":"address"},{"internalType":"uint256","name":"_index","type":"uint256"}],"name":"getDepartmentAtIndex","outputs":[{"internalType":"bytes32","name":"id","type":"bytes32"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"_organization","type":"address"},{"internalType":"bytes32","name":"_id","type":"bytes32"}],"name":"getDepartmentData","outputs":[{"internalType":"uint256","name":"userCount","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"_organization","type":"address"},{"internalType":"bytes32","name":"_depId","type":"bytes32"},{"internalType":"uint256","name":"_index","type":"uint256"}],"name":"getDepartmentUserAtIndex","outputs":[{"internalType":"address","name":"departmentMember","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"_organization","type":"address"}],"name":"getNumberOfApprovers","outputs":[{"internalType":"uint256","name":"size","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"_organization","type":"address"},{"internalType":"bytes32","name":"_depId","type":"bytes32"}],"name":"getNumberOfDepartmentUsers","outputs":[{"internalType":"uint256","name":"size","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"_organization","type":"address"}],"name":"getNumberOfDepartments","outputs":[{"internalType":"uint256","name":"size","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"getNumberOfOrganizations","outputs":[{"internalType":"uint256","name":"size","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"_organization","type":"address"}],"name":"getNumberOfUsers","outputs":[{"internalType":"uint256","name":"size","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"uint256","name":"_pos","type":"uint256"}],"name":"getOrganizationAtIndex","outputs":[{"internalType":"address","name":"organization","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"_organization","type":"address"}],"name":"getOrganizationData","outputs":[{"internalType":"uint256","name":"numApprovers","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"getUserAccountsSize","outputs":[{"internalType":"uint256","name":"size","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"_organization","type":"address"},{"internalType":"uint256","name":"_pos","type":"uint256"}],"name":"getUserAtIndex","outputs":[{"internalType":"address","name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"_organization","type":"address"},{"internalType":"address","name":"_user","type":"address"}],"name":"getUserData","outputs":[{"internalType":"address","name":"userAddress","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"_address","type":"address"}],"name":"organizationExists","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"_successor","type":"address"}],"name":"upgrade","outputs":[{"internalType":"bool","name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"_userAccount","type":"address"}],"name":"userAccountExists","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"view","type":"function"}]';
    export type Contract = ReturnType<typeof contract>;
    export const contract = (client: Provider, address: string) => ({ address, functions: { ERC165_ID_ObjectFactory(call = defaultCall): Promise<[
                Buffer
            ]> {
                const data = encode(client).ERC165_ID_ObjectFactory();
                return call<[
                    Buffer
                ]>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).ERC165_ID_ObjectFactory();
                });
            }, ERC165_ID_Upgradeable(call = defaultCall): Promise<[
                Buffer
            ]> {
                const data = encode(client).ERC165_ID_Upgradeable();
                return call<[
                    Buffer
                ]>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).ERC165_ID_Upgradeable();
                });
            }, ERC165_ID_VERSIONED_ARTIFACT(call = defaultCall): Promise<[
                Buffer
            ]> {
                const data = encode(client).ERC165_ID_VERSIONED_ARTIFACT();
                return call<[
                    Buffer
                ]>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).ERC165_ID_VERSIONED_ARTIFACT();
                });
            }, OBJECT_CLASS_ORGANIZATION(call = defaultCall): Promise<[
                string
            ]> {
                const data = encode(client).OBJECT_CLASS_ORGANIZATION();
                return call<[
                    string
                ]>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).OBJECT_CLASS_ORGANIZATION();
                });
            }, OBJECT_CLASS_USER_ACCOUNT(call = defaultCall): Promise<[
                string
            ]> {
                const data = encode(client).OBJECT_CLASS_USER_ACCOUNT();
                return call<[
                    string
                ]>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).OBJECT_CLASS_USER_ACCOUNT();
                });
            }, compareArtifactVersion(_other: string, call = defaultCall): Promise<{
                result: number;
            }> {
                const data = encode(client).compareArtifactVersion[0](_other);
                return call<{
                    result: number;
                }>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).compareArtifactVersion[0]();
                });
            }, compareArtifactVersion_1(_version: [
                number,
                number,
                number
            ], call = defaultCall): Promise<{
                result: number;
            }> {
                const data = encode(client).compareArtifactVersion[1](_version);
                return call<{
                    result: number;
                }>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).compareArtifactVersion[1]();
                });
            }, createOrganization(_initialApprovers: string[], call = defaultCall): Promise<[
                number,
                string
            ]> {
                const data = encode(client).createOrganization(_initialApprovers);
                return call<[
                    number,
                    string
                ]>(client, address, data, false, (data: Uint8Array | undefined) => {
                    return decode(client, data).createOrganization();
                });
            }, createUserAccount(_id: Buffer, _owner: string, _ecosystem: string, call = defaultCall): Promise<{
                userAccount: string;
            }> {
                const data = encode(client).createUserAccount(_id, _owner, _ecosystem);
                return call<{
                    userAccount: string;
                }>(client, address, data, false, (data: Uint8Array | undefined) => {
                    return decode(client, data).createUserAccount();
                });
            }, departmentExists(_organization: string, _departmentId: Buffer, call = defaultCall): Promise<[
                boolean
            ]> {
                const data = encode(client).departmentExists(_organization, _departmentId);
                return call<[
                    boolean
                ]>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).departmentExists();
                });
            }, getApproverAtIndex(_organization: string, _pos: number, call = defaultCall): Promise<[
                string
            ]> {
                const data = encode(client).getApproverAtIndex(_organization, _pos);
                return call<[
                    string
                ]>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).getApproverAtIndex();
                });
            }, getApproverData(_organization: string, _approver: string, call = defaultCall): Promise<{
                approverAddress: string;
            }> {
                const data = encode(client).getApproverData(_organization, _approver);
                return call<{
                    approverAddress: string;
                }>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).getApproverData();
                });
            }, getArtifactVersion(call = defaultCall): Promise<[
                [
                    number,
                    number,
                    number
                ]
            ]> {
                const data = encode(client).getArtifactVersion();
                return call<[
                    [
                        number,
                        number,
                        number
                    ]
                ]>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).getArtifactVersion();
                });
            }, getArtifactVersionMajor(call = defaultCall): Promise<[
                number
            ]> {
                const data = encode(client).getArtifactVersionMajor();
                return call<[
                    number
                ]>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).getArtifactVersionMajor();
                });
            }, getArtifactVersionMinor(call = defaultCall): Promise<[
                number
            ]> {
                const data = encode(client).getArtifactVersionMinor();
                return call<[
                    number
                ]>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).getArtifactVersionMinor();
                });
            }, getArtifactVersionPatch(call = defaultCall): Promise<[
                number
            ]> {
                const data = encode(client).getArtifactVersionPatch();
                return call<[
                    number
                ]>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).getArtifactVersionPatch();
                });
            }, getDepartmentAtIndex(_organization: string, _index: number, call = defaultCall): Promise<{
                id: Buffer;
            }> {
                const data = encode(client).getDepartmentAtIndex(_organization, _index);
                return call<{
                    id: Buffer;
                }>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).getDepartmentAtIndex();
                });
            }, getDepartmentData(_organization: string, _id: Buffer, call = defaultCall): Promise<{
                userCount: number;
            }> {
                const data = encode(client).getDepartmentData(_organization, _id);
                return call<{
                    userCount: number;
                }>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).getDepartmentData();
                });
            }, getDepartmentUserAtIndex(_organization: string, _depId: Buffer, _index: number, call = defaultCall): Promise<{
                departmentMember: string;
            }> {
                const data = encode(client).getDepartmentUserAtIndex(_organization, _depId, _index);
                return call<{
                    departmentMember: string;
                }>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).getDepartmentUserAtIndex();
                });
            }, getNumberOfApprovers(_organization: string, call = defaultCall): Promise<{
                size: number;
            }> {
                const data = encode(client).getNumberOfApprovers(_organization);
                return call<{
                    size: number;
                }>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).getNumberOfApprovers();
                });
            }, getNumberOfDepartmentUsers(_organization: string, _depId: Buffer, call = defaultCall): Promise<{
                size: number;
            }> {
                const data = encode(client).getNumberOfDepartmentUsers(_organization, _depId);
                return call<{
                    size: number;
                }>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).getNumberOfDepartmentUsers();
                });
            }, getNumberOfDepartments(_organization: string, call = defaultCall): Promise<{
                size: number;
            }> {
                const data = encode(client).getNumberOfDepartments(_organization);
                return call<{
                    size: number;
                }>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).getNumberOfDepartments();
                });
            }, getNumberOfOrganizations(call = defaultCall): Promise<{
                size: number;
            }> {
                const data = encode(client).getNumberOfOrganizations();
                return call<{
                    size: number;
                }>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).getNumberOfOrganizations();
                });
            }, getNumberOfUsers(_organization: string, call = defaultCall): Promise<{
                size: number;
            }> {
                const data = encode(client).getNumberOfUsers(_organization);
                return call<{
                    size: number;
                }>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).getNumberOfUsers();
                });
            }, getOrganizationAtIndex(_pos: number, call = defaultCall): Promise<{
                organization: string;
            }> {
                const data = encode(client).getOrganizationAtIndex(_pos);
                return call<{
                    organization: string;
                }>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).getOrganizationAtIndex();
                });
            }, getOrganizationData(_organization: string, call = defaultCall): Promise<{
                numApprovers: number;
            }> {
                const data = encode(client).getOrganizationData(_organization);
                return call<{
                    numApprovers: number;
                }>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).getOrganizationData();
                });
            }, getUserAccountsSize(call = defaultCall): Promise<{
                size: number;
            }> {
                const data = encode(client).getUserAccountsSize();
                return call<{
                    size: number;
                }>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).getUserAccountsSize();
                });
            }, getUserAtIndex(_organization: string, _pos: number, call = defaultCall): Promise<[
                string
            ]> {
                const data = encode(client).getUserAtIndex(_organization, _pos);
                return call<[
                    string
                ]>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).getUserAtIndex();
                });
            }, getUserData(_organization: string, _user: string, call = defaultCall): Promise<{
                userAddress: string;
            }> {
                const data = encode(client).getUserData(_organization, _user);
                return call<{
                    userAddress: string;
                }>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).getUserData();
                });
            }, organizationExists(_address: string, call = defaultCall): Promise<[
                boolean
            ]> {
                const data = encode(client).organizationExists(_address);
                return call<[
                    boolean
                ]>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).organizationExists();
                });
            }, upgrade(_successor: string, call = defaultCall): Promise<{
                success: boolean;
            }> {
                const data = encode(client).upgrade(_successor);
                return call<{
                    success: boolean;
                }>(client, address, data, false, (data: Uint8Array | undefined) => {
                    return decode(client, data).upgrade();
                });
            }, userAccountExists(_userAccount: string, call = defaultCall): Promise<[
                boolean
            ]> {
                const data = encode(client).userAccountExists(_userAccount);
                return call<[
                    boolean
                ]>(client, address, data, true, (data: Uint8Array | undefined) => {
                    return decode(client, data).userAccountExists();
                });
            } } as const } as const);
    export const encode = (client: Provider) => { const codec = client.contractCodec(abi); return {
        ERC165_ID_ObjectFactory: () => { return codec.encodeFunctionData("54AF67B7"); },
        ERC165_ID_Upgradeable: () => { return codec.encodeFunctionData("B21C815F"); },
        ERC165_ID_VERSIONED_ARTIFACT: () => { return codec.encodeFunctionData("E10533C6"); },
        OBJECT_CLASS_ORGANIZATION: () => { return codec.encodeFunctionData("BF90B027"); },
        OBJECT_CLASS_USER_ACCOUNT: () => { return codec.encodeFunctionData("9B3EF402"); },
        compareArtifactVersion: [(_other: string) => { return codec.encodeFunctionData("5C030138", _other); }, (_version: [
                number,
                number,
                number
            ]) => { return codec.encodeFunctionData("78BC0B0D", _version); }] as const,
        createOrganization: (_initialApprovers: string[]) => { return codec.encodeFunctionData("0EC8D39A", _initialApprovers); },
        createUserAccount: (_id: Buffer, _owner: string, _ecosystem: string) => { return codec.encodeFunctionData("C392DF6B", _id, _owner, _ecosystem); },
        departmentExists: (_organization: string, _departmentId: Buffer) => { return codec.encodeFunctionData("AB8EC038", _organization, _departmentId); },
        getApproverAtIndex: (_organization: string, _pos: number) => { return codec.encodeFunctionData("3DAF56B8", _organization, _pos); },
        getApproverData: (_organization: string, _approver: string) => { return codec.encodeFunctionData("EC89DA8B", _organization, _approver); },
        getArtifactVersion: () => { return codec.encodeFunctionData("756B2E6C"); },
        getArtifactVersionMajor: () => { return codec.encodeFunctionData("57E0EBCA"); },
        getArtifactVersionMinor: () => { return codec.encodeFunctionData("7589ADB7"); },
        getArtifactVersionPatch: () => { return codec.encodeFunctionData("F085F6DD"); },
        getDepartmentAtIndex: (_organization: string, _index: number) => { return codec.encodeFunctionData("EC9C6220", _organization, _index); },
        getDepartmentData: (_organization: string, _id: Buffer) => { return codec.encodeFunctionData("6CFB6C6B", _organization, _id); },
        getDepartmentUserAtIndex: (_organization: string, _depId: Buffer, _index: number) => { return codec.encodeFunctionData("87DE70A7", _organization, _depId, _index); },
        getNumberOfApprovers: (_organization: string) => { return codec.encodeFunctionData("CC5BAF17", _organization); },
        getNumberOfDepartmentUsers: (_organization: string, _depId: Buffer) => { return codec.encodeFunctionData("1065FFB9", _organization, _depId); },
        getNumberOfDepartments: (_organization: string) => { return codec.encodeFunctionData("AD76666D", _organization); },
        getNumberOfOrganizations: () => { return codec.encodeFunctionData("BD3A694E"); },
        getNumberOfUsers: (_organization: string) => { return codec.encodeFunctionData("851D585E", _organization); },
        getOrganizationAtIndex: (_pos: number) => { return codec.encodeFunctionData("031E8EAF", _pos); },
        getOrganizationData: (_organization: string) => { return codec.encodeFunctionData("69AD9617", _organization); },
        getUserAccountsSize: () => { return codec.encodeFunctionData("17BD60EF"); },
        getUserAtIndex: (_organization: string, _pos: number) => { return codec.encodeFunctionData("FDBB918F", _organization, _pos); },
        getUserData: (_organization: string, _user: string) => { return codec.encodeFunctionData("F4EEEFE9", _organization, _user); },
        organizationExists: (_address: string) => { return codec.encodeFunctionData("E7ABD5EA", _address); },
        upgrade: (_successor: string) => { return codec.encodeFunctionData("0900F010", _successor); },
        userAccountExists: (_userAccount: string) => { return codec.encodeFunctionData("02F53264", _userAccount); }
    }; };
    export const decode = (client: Provider, data: Uint8Array | undefined, topics: Uint8Array[] = []) => { const codec = client.contractCodec(abi); return {
        ERC165_ID_ObjectFactory: (): [
            Buffer
        ] => { return codec.decodeFunctionResult ("54AF67B7", data); },
        ERC165_ID_Upgradeable: (): [
            Buffer
        ] => { return codec.decodeFunctionResult ("B21C815F", data); },
        ERC165_ID_VERSIONED_ARTIFACT: (): [
            Buffer
        ] => { return codec.decodeFunctionResult ("E10533C6", data); },
        OBJECT_CLASS_ORGANIZATION: (): [
            string
        ] => { return codec.decodeFunctionResult ("BF90B027", data); },
        OBJECT_CLASS_USER_ACCOUNT: (): [
            string
        ] => { return codec.decodeFunctionResult ("9B3EF402", data); },
        compareArtifactVersion: [(): {
                result: number;
            } => {
                const [result] = codec.decodeFunctionResult ("5C030138", data);
                return { result: result };
            }, (): {
                result: number;
            } => {
                const [result] = codec.decodeFunctionResult ("78BC0B0D", data);
                return { result: result };
            }] as const,
        createOrganization: (): [
            number,
            string
        ] => { return codec.decodeFunctionResult ("0EC8D39A", data); },
        createUserAccount: (): {
            userAccount: string;
        } => {
            const [userAccount] = codec.decodeFunctionResult ("C392DF6B", data);
            return { userAccount: userAccount };
        },
        departmentExists: (): [
            boolean
        ] => { return codec.decodeFunctionResult ("AB8EC038", data); },
        getApproverAtIndex: (): [
            string
        ] => { return codec.decodeFunctionResult ("3DAF56B8", data); },
        getApproverData: (): {
            approverAddress: string;
        } => {
            const [approverAddress] = codec.decodeFunctionResult ("EC89DA8B", data);
            return { approverAddress: approverAddress };
        },
        getArtifactVersion: (): [
            [
                number,
                number,
                number
            ]
        ] => { return codec.decodeFunctionResult ("756B2E6C", data); },
        getArtifactVersionMajor: (): [
            number
        ] => { return codec.decodeFunctionResult ("57E0EBCA", data); },
        getArtifactVersionMinor: (): [
            number
        ] => { return codec.decodeFunctionResult ("7589ADB7", data); },
        getArtifactVersionPatch: (): [
            number
        ] => { return codec.decodeFunctionResult ("F085F6DD", data); },
        getDepartmentAtIndex: (): {
            id: Buffer;
        } => {
            const [id] = codec.decodeFunctionResult ("EC9C6220", data);
            return { id: id };
        },
        getDepartmentData: (): {
            userCount: number;
        } => {
            const [userCount] = codec.decodeFunctionResult ("6CFB6C6B", data);
            return { userCount: userCount };
        },
        getDepartmentUserAtIndex: (): {
            departmentMember: string;
        } => {
            const [departmentMember] = codec.decodeFunctionResult ("87DE70A7", data);
            return { departmentMember: departmentMember };
        },
        getNumberOfApprovers: (): {
            size: number;
        } => {
            const [size] = codec.decodeFunctionResult ("CC5BAF17", data);
            return { size: size };
        },
        getNumberOfDepartmentUsers: (): {
            size: number;
        } => {
            const [size] = codec.decodeFunctionResult ("1065FFB9", data);
            return { size: size };
        },
        getNumberOfDepartments: (): {
            size: number;
        } => {
            const [size] = codec.decodeFunctionResult ("AD76666D", data);
            return { size: size };
        },
        getNumberOfOrganizations: (): {
            size: number;
        } => {
            const [size] = codec.decodeFunctionResult ("BD3A694E", data);
            return { size: size };
        },
        getNumberOfUsers: (): {
            size: number;
        } => {
            const [size] = codec.decodeFunctionResult ("851D585E", data);
            return { size: size };
        },
        getOrganizationAtIndex: (): {
            organization: string;
        } => {
            const [organization] = codec.decodeFunctionResult ("031E8EAF", data);
            return { organization: organization };
        },
        getOrganizationData: (): {
            numApprovers: number;
        } => {
            const [numApprovers] = codec.decodeFunctionResult ("69AD9617", data);
            return { numApprovers: numApprovers };
        },
        getUserAccountsSize: (): {
            size: number;
        } => {
            const [size] = codec.decodeFunctionResult ("17BD60EF", data);
            return { size: size };
        },
        getUserAtIndex: (): [
            string
        ] => { return codec.decodeFunctionResult ("FDBB918F", data); },
        getUserData: (): {
            userAddress: string;
        } => {
            const [userAddress] = codec.decodeFunctionResult ("F4EEEFE9", data);
            return { userAddress: userAddress };
        },
        organizationExists: (): [
            boolean
        ] => { return codec.decodeFunctionResult ("E7ABD5EA", data); },
        upgrade: (): {
            success: boolean;
        } => {
            const [success] = codec.decodeFunctionResult ("0900F010", data);
            return { success: success };
        },
        userAccountExists: (): [
            boolean
        ] => { return codec.decodeFunctionResult ("02F53264", data); }
    }; };
}