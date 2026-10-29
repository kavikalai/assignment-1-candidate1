
# Checkpoint Coordinator

## Approach

The coordinator maintains the active replicas, each replica's
current checkpoint, the proposed checkpoint, the committed checkpoint,
and the replicas that acknowledged the current proposal.

Replicas are processed in their original order. Replicas that cannot
catch up to the current proposal are removed.

When a replica proposes a higher checkpoint, acknowledgements for the
previous proposal are discarded. A proposal is committed after two
different replicas acknowledge it.

The coordinator stops when the committed proposal has been acknowledged
by every active replica, or when only one replica remains.

## Assumptions

- Every replica starts at checkpoint 0.
- get_checkpoint_advance returns a non-negative integer.
- The coordinator maintains checkpoint values internally because the
  provided brief does not specify a checkpoint getter or setter on Replica.
- Each replica object represents a distinct replica.
- Test doubles simulate the Replica interface for deterministic tests.

## Known limitations

The original Replica implementation was not included in the brief.
The coordinator's internal checkpoint state and the assumed Replica
interface should be reconciled if the actual implementation becomes
available.

## Run tests

ruby -Itest test/checkpoint_coordinator_test.rb
