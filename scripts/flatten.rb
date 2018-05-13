require 'optparse'
require 'ostruct'
require 'csv'
require 'byebug'
require 'facets'

require_relative './polling_area.rb'

#Testing with bc data: rvmDo ruby ./flatten.rb -f ../rawData/bc/provincialvotingresults.csv -p AFFLIATION -v VOTES_CONSIDERED -e ED_ABBREVIATION -o VA_CODE

    ########################################################################
    # Just print a line to indicate progress
    # @param [String] doingWhatStr What do you want to tell the user you are doing
    ########################################################################
    def printProgress(doingWhatStr, count, total, zeroBased = false)
        return if total <= 2
        count += 1 if zeroBased == true
        puts "Started #{DateTime.now.strftime('%H:%M:%S')}" if count == 1
        progressStr = "#{count} / #{total} #{(count.to_f * 100/total).round} %"
        print ("\u001b[1000D" + progressStr + ' : ' + doingWhatStr)
        if count == total
            puts "\n"
            puts "Done #{DateTime.now.strftime('%H:%M:%S')}"
            puts "\n"
        else
            print '... '
        end
    end



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

def getValue(row, header, keyType)
    header = header.to_s if keyType == String
    header = header.to_sym if keyType == Symbol
    return row[header]
end

def suffixBeforeFileType(filePath)
    fileParts = filePath.split('.')
    fileTypeSuffix = fileParts.pop

    fileParts.push("flattened")
    fileParts.push(fileTypeSuffix)

    fileParts.join('.')
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
    $stderr.puts "The headers are: #{getHeaders(filePath).join("\t")}" if File.exists?((filePath or ''))
    exit 1
end


if not File.exists?(filePath)
    $stderr.puts "File #{filePath} does not exist"
    exit 1
end


seperator=detectSeperator(filePath)


### Check if the indirected headers are there
[:party_header, :votes_header, :edId_header, :edId_header, :pollingAreaId_header].each {|header|
    if not getHeaders(filePath).include?(options[header])
        $stderr.puts %Q[Header #{options[header]} does not exist.  Available headers are #{getHeaders(filePath).join("\t")}]
        exit 1
    end
}

resultsFlatten={}

totalLines = `wc -l "#{filePath}"`.strip.split(' ')[0].to_i - 1

CSV.open(filePath, 'rb', headers: :first_row, encoding: 'ISO-8859-1', col_sep: seperator) do |csv|
    csv.each_with_index do |row, i|
        keyType = row.headers.first.class

        eda         = getValue(row, options[:edId_header], keyType)
        pollingArea = getValue(row, options[:pollingAreaId_header],          keyType)
        votes       = getValue(row, options[:votes_header],         keyType)
        affiliation = getValue(row, options[:party_header],         keyType)

        next if eda.blank? or pollingArea.blank?
        identifier = eda + pollingArea

        printProgress("Reading & parsing #{identifier}", i, totalLines, true)

        resultsFlatten[identifier] = PollingArea.new(eda, pollingArea) if resultsFlatten[identifier].nil?

        resultsFlatten[identifier].addResults(affiliation, votes) if affiliation.present?

    end
end

puts "#{resultsFlatten.count} polling area objects created from flattening #{totalLines} rows"


writeToFilePath = suffixBeforeFileType(filePath)
CSV.open(writeToFilePath, 'wb') do |csv|
    csv << resultsFlatten.values.first.toCsv.keys


    resultsFlatten.each_with_index {|(identifier, pollingAreaObj), i|
        printProgress("Writting #{identifier}", i, resultsFlatten.count, true)
        next if pollingAreaObj.getTotalVotes == 0
        csv << pollingAreaObj.toCsv.values
    }
end

puts "Done writting to #{writeToFilePath}"




