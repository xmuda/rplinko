module Plinko
  class Bet
    attr_reader :txid, :vout, :amount, :payto, :mult
  
    def initialize(txid,vout,line)
      b=Daemon.transaction(txid)
      i=b["vin"][0]
      o=Daemon.transaction(i["txid"])
      @txid=txid
      @vout=vout
      @amount=b["vout"][vout]["value"]
      @payto=o["vout"][i["vout"]]["scriptPubKey"]["addresses"][0] # works for p2pkh spends only
      @mult=nil #unprocessed
      @line=line
    end
    
    def calculate!(secret)
      if @amount<MINBET || @amount>MAXBET
        @mult=1
        @slot=-10
      else
        @luckyhash=Digest::SHA256.hexdigest("#{@txid}:#{@vout}:#{secret}")
        @luckybits="%016b" % @luckyhash[60..63].hex.to_i
        @slot=@luckybits.count("1")-8
        @mult=@line[@slot.abs]
      end
      self
    end
    
    def calculated?() !@mult.nil? end
    def to_s() "Bet - #{@amount} by #{@payto} (#{@txid}:#{@vout})" end
  end
end