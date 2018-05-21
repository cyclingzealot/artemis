require 'optparse'
require 'byebug'
require 'ostruct'
require 'facets'
require 'csv'

require_relative './library.rb'


options = OpenStruct.new
op = OptionParser.new do |opt|
  opt.on('-a', '--affilation FILE_PATH', 'the path to the affilation file') { |o| options[:affiliationPath] = o }
  opt.on('-p', '--resultsDir RESULT_DIR_PATH', 'The path of the dir to the results file') { |o| options[:dirResults] = o }
end

helpStr = op.help()
helpStr = "This parses ontario files that have candidate names, not party affiliation\n" + helpStr
op.parse!

if options.to_h.count < 2
    $stderr.puts "\nAll args are required\n\n#{helpStr}\n"
    exit 1
end

affiliationPath = options[:affiliationPath]
resultsDir = options[:dirResults]


# Check if the supplied paths are valid
if not File.exists?(affiliationPath)
    $stderr.puts "File #{affiliationPath} does not exist"
    exit 1
end

if not Dir.exists?(resultsDir)
    $stderr.puts "The directory #{resultsDir} does not exist"
    exit 1
end

### Check headers of CSV file
requiredHeadersAffiliation = ["Riding", "Candidate", "Party"]
if checkHeaders(affiliationPath, requiredHeadersAffiliation)
    $stderr.puts "The file #{affiliationPath} must have the headers #{requiredHeadersAffiliation.join}"
end


### Build a lookup table for names
lastNameLookups = {}
CSV.open(affiliationPath, headers: :first_row) do |csv|
    csv.each do |row|
        nameParts = row["Candidate"].strip.split(' ')
        lastName = nameParts.last.downcase
        exceptFirstName = nil
        exceptFirstName = nameParts.drop(1).join(' ').downcase if nameParts.count > 2


        [lastName, exceptFirstName].each {|nameLike|
            next if nameLike.nil?
            lastNameLookups[nameLike] = [] if lastNameLookups[nameLike].nil?
            lastNameLookups[nameLike] << row
        }


    end
end


### For every file csv file in resultsDir
exactMatches = []
noMatches = []
multiMatches = []
Dir.foreach(resultsDir) do |csvFile|
    next if csvFile == '.' or csvFile == '..' or not csvFile.ends_with?('.csv')

    # Get the EDA ID
    edaId = /[0-9]{3}/.match(csvFile).to_a[0].to_i.to_s

    CSV.open(resultsDir + '/' + csvFile, headers: :first_row) do |csv|
        csv.each_with_index do |row, i|
            next if i > 0

            # Find the candidate headers
            candidates = row.headers[3..15].select {|h| h.present? }

            # Figure out their affilation
            candidateAffiliation = {}
            candidates.each {|c|
                lookup = c.downcase
                case (lastNameLookups[lookup] or []).count
                    when 1
                        candidateAffiliation[c] = lastNameLookups[lookup][0]["Party"]
                        exactMatches.push(c)
                    when 0
                        noMatches.push(c)
                    else
                        multiMatches.push(c)
                end
            }

            # Create a new polling area object

        end

    end
end

puts "No match for #{noMatches.sort.join(', ')}"
puts
puts "Multi match for #{multiMatches.sort.join(', ')}"
#puts "Total candidates: " +.sum.to_s



# At this point we have too many multiple maches to bother.  If we hada list of ridings ids with their names, that could help, but we don't
