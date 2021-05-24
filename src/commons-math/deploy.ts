import { Client } from '@hyperledger/burrow';
import { DefaultApplicationRegistry } from '../bpm-runtime/DefaultApplicationRegistry.abi';
import { Addition } from './Addition.abi';
import { Decrement } from './Decrement.abi';
import { Division } from './Division.abi';
import { GreaterThan } from './GreaterThan.abi';
import { GreaterThanEqual } from './GreaterThanEqual.abi';
import { Increment } from './Increment.abi';
import { IsEqual } from './IsEqual.abi';
import { IsNotEqual } from './IsNotEqual.abi';
import { LessThan } from './LessThan.abi';
import { LessThanEqual } from './LessThanEqual.abi';
import { MakeZero } from './MakeZero.abi';
import { Multiplication } from './Multiplication.abi';
import { Subtraction } from './Subtraction.abi';

async function addApplication(
  registry: Promise<DefaultApplicationRegistry.Contract>,
  _id: string,
  _type: number,
  _location: Promise<string>,
  _function: string,
  _webForm: string,
) {
  return (await registry).functions.addApplication(
    Buffer.from(_id),
    _type,
    await _location,
    Buffer.from(_function),
    Buffer.from(_webForm),
  );
}

async function addAccessPoint(
  registry: Promise<DefaultApplicationRegistry.Contract>,
  _id: string,
  _accessPointId: string,
  _dataType: number,
  _direction: number,
) {
  return (await registry).functions.addAccessPoint(
    Buffer.from(_id),
    Buffer.from(_accessPointId),
    _dataType,
    _direction,
  );
}

export async function DeployNumbers(client: Client, registry: Promise<DefaultApplicationRegistry.Contract>) {
  const addition = Addition.deploy(client);
  const subtraction = Subtraction.deploy(client);
  const multiplication = Multiplication.deploy(client);
  const division = Division.deploy(client);
  const zeroize = MakeZero.deploy(client);
  const increment = Increment.deploy(client);
  const decrement = Decrement.deploy(client);
  const isEqual = IsEqual.deploy(client);
  const isNotEqual = IsNotEqual.deploy(client);
  const greaterThan = GreaterThan.deploy(client);
  const greaterThanEqual = GreaterThanEqual.deploy(client);
  const lessThan = LessThan.deploy(client);
  const lessThanEqual = LessThanEqual.deploy(client);

  await Promise.all([
    addApplication(registry, 'Numbers - Addition', 1, addition, '', ''),
    addApplication(registry, 'Numbers - Subtraction', 1, subtraction, '', ''),
    addApplication(registry, 'Numbers - Multiplication', 1, multiplication, '', ''),
    addApplication(registry, 'Numbers - Division', 1, division, '', ''),
    addApplication(registry, 'Numbers - Zeroize', 1, zeroize, '', ''),
    addApplication(registry, 'Numbers - Increment', 1, increment, '', ''),
    addApplication(registry, 'Numbers - Decrement', 1, decrement, '', ''),
    addApplication(registry, 'Numbers - IsEqual', 1, isEqual, '', ''),
    addApplication(registry, 'Numbers - IsNotEqual', 1, isNotEqual, '', ''),
    addApplication(registry, 'Numbers - GreaterThan', 1, greaterThan, '', ''),
    addApplication(registry, 'Numbers - GreaterThanEqual', 1, greaterThanEqual, '', ''),
    addApplication(registry, 'Numbers - LessThan', 1, lessThan, '', ''),
    addApplication(registry, 'Numbers - LessThanEqual', 1, lessThanEqual, '', ''),
  ]);

  await Promise.all([
    addAccessPoint(registry, 'Numbers - Addition', 'numberInOne', 8, 0),
    addAccessPoint(registry, 'Numbers - Addition', 'numberInTwo', 8, 0),
    addAccessPoint(registry, 'Numbers - Addition', 'numberOut', 8, 1),
    addAccessPoint(registry, 'Numbers - Subtraction', 'numberInOne', 8, 0),
    addAccessPoint(registry, 'Numbers - Subtraction', 'numberInTwo', 8, 0),
    addAccessPoint(registry, 'Numbers - Subtraction', 'numberOut', 8, 1),
    addAccessPoint(registry, 'Numbers - Multiplication', 'numberInOne', 8, 0),
    addAccessPoint(registry, 'Numbers - Multiplication', 'numberInTwo', 8, 0),
    addAccessPoint(registry, 'Numbers - Multiplication', 'numberOut', 8, 1),
    addAccessPoint(registry, 'Numbers - Division', 'numberInOne', 8, 0),
    addAccessPoint(registry, 'Numbers - Division', 'numberInTwo', 8, 0),
    addAccessPoint(registry, 'Numbers - Division', 'numberOut', 8, 1),
    addAccessPoint(registry, 'Numbers - Zeroize', 'numberOut', 8, 1),
    addAccessPoint(registry, 'Numbers - Increment', 'numberIn', 8, 0),
    addAccessPoint(registry, 'Numbers - Increment', 'numberOut', 8, 1),
    addAccessPoint(registry, 'Numbers - Decrement', 'numberIn', 8, 0),
    addAccessPoint(registry, 'Numbers - Decrement', 'numberOut', 8, 1),
    addAccessPoint(registry, 'Numbers - IsEqual', 'numberInOne', 8, 0),
    addAccessPoint(registry, 'Numbers - IsEqual', 'numberInTwo', 8, 0),
    addAccessPoint(registry, 'Numbers - IsEqual', 'result', 1, 1),
    addAccessPoint(registry, 'Numbers - IsNotEqual', 'numberInOne', 8, 0),
    addAccessPoint(registry, 'Numbers - IsNotEqual', 'numberInTwo', 8, 0),
    addAccessPoint(registry, 'Numbers - IsNotEqual', 'result', 1, 1),
    addAccessPoint(registry, 'Numbers - GreaterThan', 'numberInOne', 8, 0),
    addAccessPoint(registry, 'Numbers - GreaterThan', 'numberInTwo', 8, 0),
    addAccessPoint(registry, 'Numbers - GreaterThan', 'result', 1, 1),
    addAccessPoint(registry, 'Numbers - GreaterThanEqual', 'numberInOne', 8, 0),
    addAccessPoint(registry, 'Numbers - GreaterThanEqual', 'numberInTwo', 8, 0),
    addAccessPoint(registry, 'Numbers - GreaterThanEqual', 'result', 1, 1),
    addAccessPoint(registry, 'Numbers - LessThan', 'numberInOne', 8, 0),
    addAccessPoint(registry, 'Numbers - LessThan', 'numberInTwo', 8, 0),
    addAccessPoint(registry, 'Numbers - LessThan', 'result', 1, 1),
    addAccessPoint(registry, 'Numbers - LessThanEqual', 'numberInOne', 8, 0),
    addAccessPoint(registry, 'Numbers - LessThanEqual', 'numberInTwo', 8, 0),
    addAccessPoint(registry, 'Numbers - LessThanEqual', 'result', 1, 1),
  ]);
}
