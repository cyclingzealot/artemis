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



########################################################################
# Writes a hash of polling areas to a file
# OTher than for user output output, the key of the hash is not important
# It should be unique of course to the polling area
########################################################################
def writePollingAreas(filePath, resultsFlatten)
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
end


def detectSeperator(filePath)
    seperators = [';', ':', "\t", ',', '|']
    firstLine = getFirstLine(filePath)

    seperators.max_by{ |s|
        firstLine.split(s).count
    }
end


def checkHeaders(filePath, headersWanted)
    headers = getHeaders(filePath)
    headersWanted.all?{ |headW| headers.include?(headW)}
end

def getFirstLine(filePath)
    File.open(filePath, &:readline)
end

def getHeaders(filePath)
    sep = detectSeperator(filePath)
    getFirstLine(filePath).split(sep)
end

########################################################################
# Get the value of a row cell, regardless if it's a string or symbol
########################################################################
def getValue(row, header, keyType)
    header = header.to_s if keyType == String
    header = header.to_sym if keyType == Symbol
    return row[header]
end

########################################################################
# Adds a suffix to a file name but before the file type
########################################################################
def suffixBeforeFileType(filePath, suffix)
    fileParts = filePath.split('.')
    fileTypeSuffix = fileParts.pop

    fileParts.push("flattened")
    fileParts.push(fileTypeSuffix)

    fileParts.join('.')
end

