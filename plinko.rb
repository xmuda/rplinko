#!/usr/bin/env ruby
require 'highlander'
require 'json'
require 'digest'
require 'date'

module Plinko
  DAEMON="./clamd"
  CHANGE="xCNR1AUJZBRWF1uCFdqvWtD2hsYk2fitcT"
  LINES={
    "xSFbh3pzpBrdfUtkN9JgSEW4f83LrjaHJv" => [0.2,0.2,0.2,2,4,9,24,130,999]
  }
  FEE=0.0001
  MINCHANGE=0.00001
  MINBET=0.001
  MAXBET=0.1

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

if __FILE__ == $0
  secrethash = Digest::SHA256.hexdigest("just dice is filled with pole smokers:#{Date.new}")
  unplayed, hotwallet = [], []
  list = Plinko::Daemon.unspent
  for utxo in list do
    if utxo["address"].include? Plinko::CHANGE
      hotwallet << utxo
    else
      for address, line in Plinko::LINES do
        unplayed << Plinko::Bet.new(utxo["txid"],utxo["vout"],line) if utxo["address"].include? address 
      end
    end
  end
  hotwallet.sort! { |a, b| a["amount"] <=> b["amount"] }
  for bet in unplayed do
    puts "Received #{bet.calculate!(secrethash)}"
    puts "Processed #{Plinko::Payment.new(bet,hotwallet).broadcast!}"
  end
end

# this comment still serves no purpose