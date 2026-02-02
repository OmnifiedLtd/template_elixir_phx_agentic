defmodule PhxAgenticTemplate.QueuesTest do
  use PhxAgenticTemplate.DataCase, async: true

  alias PhxAgenticTemplate.Queues

  test "list_queues includes configured queues" do
    queues = Queues.list_queues()

    assert Enum.any?(queues, &(&1.name == "default"))
    assert Enum.all?(queues, &(&1.status in [:running, :paused, :stopped]))
  end

  test "enqueue_demo_jobs inserts jobs" do
    jobs = Queues.enqueue_demo_jobs("default", 2)

    assert length(jobs) == 2
  end

  test "queue_job_counts returns totals" do
    _jobs = Queues.enqueue_demo_jobs("default", 1)

    counts = Queues.queue_job_counts()

    assert get_in(counts, ["default", "total"]) >= 1
  end
end
