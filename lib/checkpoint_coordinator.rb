
class CheckpointCoordinator
  def initialize(replicas)
    raise ArgumentError, "At least two replicas are required" if replicas.size < 2

    @replica_order = replicas.dup
    @replicas = replicas.dup

    @checkpoints = replicas.to_h { |replica| [replica, 0] }

    @proposed_checkpoint = 0
    @committed_checkpoint = 0
    @acknowledgements = []
    @last_replica = nil
  end

  def run
    loop do
      # Stop immediately if only one replica remains.
      break if @replicas.size <= 1

      replica = next_replica
      advance = replica.get_checkpoint_advance
      target = @checkpoints.fetch(replica) + advance

      # A replica that cannot catch up is removed.
      if target < @proposed_checkpoint
        @replicas.delete(replica)
        @acknowledgements.delete(replica)
        next
      end

      # A higher target replaces the current proposal.
      if target > @proposed_checkpoint
        @proposed_checkpoint = target
        @acknowledgements = [replica]
      else
        # Record this replica's acknowledgement only once.
        @acknowledgements |= [replica]
      end

      # Apply the checkpoint only after it can catch up.
      @checkpoints[replica] = target

      if @acknowledgements.size >= 2
        @committed_checkpoint = @proposed_checkpoint
      end

      # Do not give another replica a turn after completion.
      if @committed_checkpoint == @proposed_checkpoint &&
         @replicas.all? { |r| @acknowledgements.include?(r) }
        break
      end
    end

    {
      checkpoint: @committed_checkpoint,
      replicas: @replicas,
      proposed_checkpoint: @proposed_checkpoint
    }
  end

  private

  def next_replica
    last_index = @last_replica ? @replica_order.index(@last_replica) : -1

    @replica_order.size.times do |offset|
      index = (last_index + offset + 1) % @replica_order.size
      candidate = @replica_order[index]

      next unless @replicas.include?(candidate)

      @last_replica = candidate
      return candidate
    end

    raise "No active replica available"
  end
end
