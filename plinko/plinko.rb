module Plinko
  DAEMON="~/clam-*/bin/clamd"
  CHANGE="xCNR1AUJZBRWF1uCFdqvWtD2hsYk2fitcT"
  LINES={
    "xSFbh3pzpBrdfUtkN9JgSEW4f83LrjaHJv" => [0.2,0.2,0.2,2,4,9,24,130,999]
  }
  FEE=0.0001
  MINCHANGE=0.00001
  MINBET=0.001
  MAXBET=0.1
end

require 'json'
require 'digest'
require './daemon'
require './bet'
require './payment'
