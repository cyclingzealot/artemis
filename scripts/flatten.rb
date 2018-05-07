require 'optparse'
require 'ostruct'

#https://stackoverflow.com/questions/26434923/parse-command-line-arguments-in-a-ruby-script#26444165
options = OpenStruct.new
OptionParser.new do |opt|
  opt.on('-f', '--party_header PARTY_HEADER', 'The header of the column for party name') { |o| options[:party_header] = o }
  opt.on('-v', '--votes_header VOTES_HEADER', 'The header of the column that has the number of the votes') { |o| options[:votes_header] = o }
  opt.on('-e', '--edId_header EDID_HEADER', 'The header of the column for the electoral district identifier') { |o| options[:edId_header] = o }
  opt.on('-p', '--pollingAreaId_header POLLINGAREA_HEADER', 'The header of the column that has the identifer for polling area') { |o| options[:pollingAreaId_header] = o }
end.parse!


CSV.open(filePath)
