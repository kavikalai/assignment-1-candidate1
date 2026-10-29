
require "minitest/autorun"
require_relative "../lib/checkpoint_coordinator"

class FakeReplica
  def initialize(*advances)
    @advances = advances.dup
  end

  def get_checkpoint_advance
    @advances.shift || 0
  end

  def remaining_advances
    @advances.dup
  end
end

class CheckpointCoordinatorTest < Minitest::Test
  def test_commits_when_two_replicas_acknowledge_same_checkpoint
    a = FakeReplica.new(10)
    b = FakeReplica.new(10)
    c = FakeReplica.new(10)

    result = CheckpointCoordinator.new([a, b, c]).run

    assert_equal 10, result[:checkpoint]
    assert_equal [a, b, c], result[:replicas]
  end

  def test_stops_immediately_after_every_replica_acknowledges
    a = FakeReplica.new(10)
    b = FakeReplica.new(10)
    c = FakeReplica.new(10, 100)

    result = CheckpointCoordinator.new([a, b, c]).run

    assert_equal 10, result[:checkpoint]
    assert_equal [100], c.remaining_advances
  end

  def test_replaces_an_uncommitted_proposal_with_a_higher_one
    a = FakeReplica.new(10, 5)
    b = FakeReplica.new(12, 3)
    c = FakeReplica.new(5)

    result = CheckpointCoordinator.new([a, b, c]).run

    assert_equal 15, result[:checkpoint]
    assert_equal [a, b], result[:replicas]
  end

  def test_removes_replica_that_cannot_catch_up
    a = FakeReplica.new(10)
    b = FakeReplica.new(5)
    c = FakeReplica.new(10)

    result = CheckpointCoordinator.new([a, b, c]).run

    assert_equal 10, result[:checkpoint]
    assert_equal [a, c], result[:replicas]
  end

  def test_discards_higher_uncommitted_proposal
    a = FakeReplica.new(20, 10)
    b = FakeReplica.new(20, 5)
    c = FakeReplica.new(0)

    result = CheckpointCoordinator.new([a, b, c]).run

    assert_equal 20, result[:checkpoint]
    assert_equal [a], result[:replicas]
  end

  def test_rejects_fewer_than_two_replicas
    assert_raises(ArgumentError) do
      CheckpointCoordinator.new([FakeReplica.new])
    end
  end
end

