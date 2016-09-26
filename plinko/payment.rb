module Plinko
  class Payment
    def initialize(bet,nonbet)
      raise "Tried to process uncalculated bet!" unless bet.calculated?
      @payout=(bet.amount*bet.mult).round(8)
      unless @payout < MINCHANGE + FEE
        @payto=bet.payto
        @txid=nil #unbroadcast
        @coins=[{"txid"=>bet.txid,"vout"=>bet.vout}]
        @sum=bet.amount
        while @sum < sendval do
          raise "Not enough money!" if nonbet.size==0
          @sum += nonbet[0]["amount"]
          @coins << nonbet.delete_at(0)
        end
        for i in @coins do
          i.delete_if {|key| !["txid","vout"].include?(key)}
        end
      else
        @txid="Too small for refund"        
      end
    end
  
    def broadcast!
      return self if broadcast?
      tx = {@payto=>(@payout-FEE).round(8)}
      tx << {CHANGE=>(@sum-sendval).round(8)} if @sum-MINCHANGE>sendval
      @txid = Daemon.send(@coins,tx)
      self
    end
  
    def sendval() @payout + (FEE * ((@coins.size/5).floor)) end
    def broadcast?() !@txid.nil? end
    def to_s() "Payment - #{@payout} to #{@payto} (#{@txid.nil? ? 'Unsent' : @txid})" end
  end
end
