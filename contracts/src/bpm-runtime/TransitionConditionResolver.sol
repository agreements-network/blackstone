pragma solidity ^0.5;

interface TransitionConditionResolver {

    function resolveTransitionCondition(bytes32 _transitionId, bytes32 _targetId) external view returns (bool);
}