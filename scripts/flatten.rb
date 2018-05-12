require 'optparse'
require 'ostruct'
require 'csv'
require 'byebug'


def detectSeperator(filePath)
    seperators = [';', ':', "\t", ',', '|']
    firstLine = getFirstLine(filePath)

    seperators.max_by{ |s|
        firstLine.split(s).count
    }
end

def getFirstLine(filePath)
    File.open(filePath, &:readline)
end

def getHeaders(filePath)
    sep = detectSeperator(filePath)
    getFirstLine(filePath).split(sep)
end

#https://stackoverflow.com/questions/26434923/parse-command-line-arguments-in-a-ruby-script#26444165
options = OpenStruct.new
op = OptionParser.new do |opt|
  opt.on('-f', '--file FILE_PATH', 'the path of the file') { |o| options[:file_path] = o }
  opt.on('-p', '--party_header PARTY_HEADER', 'The header of the column for party name') { |o| options[:party_header] = o }
  opt.on('-v', '--votes_header VOTES_HEADER', 'The header of the column that has the number of the votes') { |o| options[:votes_header] = o }
  opt.on('-e', '--edId_header EDID_HEADER', 'The header of the column for the electoral district identifier') { |o| options[:edId_header] = o }
  opt.on('-o', '--pollingAreaId_header POLLINGAREA_HEADER', 'The header of the column that has the identifer for polling area') { |o| options[:pollingAreaId_header] = o }
end

helpStr = op.help()
op.parse!

filePath = options[:file_path]

if options.to_h.count < 5
    $stderr.puts "\nAll args are required\n\n#{helpStr}\n"
    $stderr.puts "The headers are: #{getHeaders(filePath).join("\t")}" if not filePath.nil? and File.exists?(filePath)
    exit 1
end


if not File.exists?(filePath)
    $stderr.puts "File #{filePath} does not exist"
    exit 1
end





#CSV.open(filePath)
