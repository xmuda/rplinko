module Plinko
  class Daemon
    @@DAEMON=DAEMON
    def Daemon::unspent() JSON.parse(%x`#{@@DAEMON} listunspent`) end
    def Daemon::transaction(txid) JSON.parse(%x`#{@@DAEMON} getrawtransaction #{txid} 1`) end
    def Daemon::send(inputs,outputs)
      tx = %x`#{@@DAEMON} createrawtransaction '#{inputs.to_json}' '#{outputs.to_json}'`
      tx = JSON.parse %x`#{@@DAEMON} signrawtransaction #{tx}`
      %x`#{@@DAEMON} sendrawtransaction #{tx["hex"]}`
    end
    
  private
    def initialize() raise "Cannot instance this class" end
  end
end