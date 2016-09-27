#!/usr/bin/env ruby
require 'date'
require './plinko/plinko'

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
