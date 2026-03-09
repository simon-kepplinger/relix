defmodule Relix.Commands.Psync do
  @empty_rdb Base.decode64!(
               "UkVESVMwMDEx+glyZWRpcy12ZXIFNy4yLjD6CnJlZGlzLWJpdHPAQPoFY3RpbWXCbQi8ZfoIdXNlZC1tZW3CsMQQAPoIYW9mLWJhc2XAAP/wbjv+wP9aog=="
             )

  def dispatch(_) do
    replid = Relix.Replication.master_replid()
    offset = Relix.Replication.replication_offset()

    {:batch,
     [
       {:simple, "FULLRESYNC #{replid} #{offset}"},
       {:file, @empty_rdb}
     ]}
  end
end
